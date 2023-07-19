  class ImageUploadService
    require 'open-uri'
    require 'tempfile'
    require 'mini_magick'

    MAX_FILE_SIZE = 20 * 1000 * 1000 # 20 MB

    attr_reader :image_url, :mint, :socket_id, :large

    def initialize(image_url:, mint:, socket_id:)
      @image_url = image_url
      @mint = mint
      @socket_id = socket_id
    end

    def call
      upload_image
    end

    def call_large_image
      upload_large_image
    end

    def self.upload_batch(tokens, socket_id)
      results = []
      later = []
      tokens.each do |token|
        # skip if no mint
        next unless token.key?('mint') && token['mint'].present?

        if token.key?('error') || !token.key?('image')
          ActionCable.server.broadcast("notifications_#{socket_id}", {
            message: 'Optimizing Error', 
            data: { mint: token["mint"], error: "No Image Metadata Found: #{token['error']}" }
          })
          results << token
        else 
          begin
            cldResult = new(image_url: token["image"], mint: token["mint"], socket_id: socket_id).call

            if cldResult["public_id"].present?
              puts "Uploaded: #{token["mint"]}"
              ActionCable.server.broadcast("notifications_#{socket_id}", {
                message: 'Image Optimized', 
                data: { mint: token["mint"], imageId: cldResult["public_id"] }
              })

              results << { imageId: cldResult['public_id'], mint: token['mint'] }
            else 
              puts "Saving large upload for last: #{token['mint']}"
              ActionCable.server.broadcast("notifications_#{socket_id}", {
                message: 'Image Queued', 
                data: { mint: token["mint"], imageId: nil }
              })

              later << token
            end
          rescue => e
            puts "Error uploading image for mint #{token["mint"]}: #{e.message}"
            ActionCable.server.broadcast("notifications_#{socket_id}", {
              message: 'Optimizing Error', 
              data: { mint: token['mint'], error: "Error Optimizating Image: #{e.message}" }
            })
            results << { fallbackImage: token['image'], mint: token['mint'], error: "Error Optimizating Image: #{e.message}" }
          end
        end
      end
      
      optimizedResults = results.map do |result|
        if result.key?(:imageId) 
          { 
            mint_address: result[:mint], 
            optimized: 'True', 
            error_message: nil, 
            created_at: Time.current,
            updated_at: Time.current
          }
        else 
          { 
            mint_address: result[:mint], 
            optimized: 'Error', 
            error_message: result[:error] || "Error Optimizating Image", 
            created_at: Time.current,
            updated_at: Time.current
          }
        end
      end

      OptimizedImage.upsert_all(optimizedResults, unique_by: :mint_address) if optimizedResults.present?

      later.each do |token|
        cldResult = new(image_url: token["image"], mint: token["mint"], socket_id: socket_id).call_large_image
      end

      puts "Done Uploading #{results.count} Images, #{later.count} Resized"

      results
    end


    private

    def upload_image
      begin
        response = Cloudinary::Uploader.upload(image_url, resource_type: "auto", public_id: "#{ENV['CLOUDINARY_NFT_FOLDER']}/#{mint}", overwrite: true)
        response
      rescue => e
        if e.message.include?("File size too large")

          # when enabling async jobs remember to remove the later array/loop from upload_batch
          # puts "Queueing Scale Down Job: #{mint}"
          # OptimizeImageJob.perform_later(image_url, mint, socket_id)

          { }
        else
          raise
        end
      end
    end

    def upload_large_image
      
      begin
        puts "Image too large, Scaling Down: #{mint}"
        image_file = download_image(image_url)
        scale_image(image_file)

        cldResult = Cloudinary::Uploader.upload(image_file.path, resource_type: "auto", public_id: "#{ENV['CLOUDINARY_NFT_FOLDER']}/#{mint}", overwrite: true)
        image_file.close
        image_file.unlink # delete the temporary file
        
        ActionCable.server.broadcast("notifications_#{socket_id}", {
          message: 'Image Optimized', 
          data: { mint: mint, imageId: cldResult["public_id"] }
        })

        optimized = OptimizedImage.where(mint_address: mint).first_or_create
        optimized.update(optimized: "True", error_message: nil)
        puts "Uploaded Large: #{mint}"
      rescue => e
        puts "Error uploading large image: #{e.message}"
        ActionCable.server.broadcast("notifications_#{socket_id}", {
          message: 'Optimizing Error', 
          data: { mint: mint, error: e.message }
        })
        optimized = OptimizedImage.where(mint_address: mint).first_or_create
        optimized.update(optimized: "Error", error_message: "Error Optimizing: #{e.message}")
      end
    end

    def download_image(url)
      data = URI.open(url).read
      file = Tempfile.new('image')
      file.binmode
      file.write(data)
      file.rewind
      file
    end

    def scale_image(image_file)
      max_size = MAX_FILE_SIZE * 0.75

      image = MiniMagick::Image.open(image_file.path)
      
      scaleSize = 2000

      if(image.width < scaleSize) 
        scaleSize = image.width * 0.75
      end

      image.resize("#{scaleSize}x")

      if image.size > max_size
        image.resize("#{scaleSize * 0.75}x")
      end

      image.write(image_file.path)
    end
  end


    # max_size = MAX_FILE_SIZE * 0.75
    # max_iterations = 20

    # image = MiniMagick::Image.open(image_file.path)
    # puts "Original Image Size: #{image.size}"

    # image.format('webp')
    
    # max_width = image.width
    # min_width = 1
    # width = max_width
    
    # puts "original width: #{width}"

    # size = image.size
    # org_width = image.width

    # if size > max_size
    #   max_iterations.times do
    #     width = (min_width + max_width) / 2

    #     estimated_size = (size * (width.to_f / org_width)).round

    #     if estimated_size > max_size
    #       max_width = width - (0.1 * width).round
    #     else
    #       min_width = width + (0.1 * width).round
    #     end

    #     break if max_width <= min_width
    #   end
    #   image.resize("#{width}x")
    # end

    # puts "New Image Size: #{image.size}"
    # puts "New Image Width: #{image.width}"

    # image.write(image_file.path)
