  class ImageUploadService
    require 'open-uri'
    require 'tempfile'
    require 'mini_magick'

    MAX_FILE_SIZE = 20 * 1000 * 1000 # 20 MB

    attr_reader :image_url, :mint, :socket_id, :large, :cld_id

    def initialize(image_url:, cld_id:, socket_id:)
      # @mint = mint
      @cld_id = cld_id
      @image_url = image_url
      @socket_id = socket_id
    end

    def call
      upload_image
    end

    def call_large_image
      upload_large_image
    end

    def self.clean(text)
      # Remove special characters and https/http from image link to use as an identifier
      text.gsub(/[^\w]/, '').gsub('https', '').gsub('http', '')
    end

    def self.get_token_cld_id(token)
      if token['is_edition'] && token['image']
        "edition-#{clean(token['image'])}"
      else
        token['mint']
      end
    end

    def self.upload_batch(tokens, socket_id)
      results = []
      later = []
      tokens.each do |token|
        # skip if no mint
        next unless token.key?('mint') && token['mint'].present?
        cld_id = get_token_cld_id(token)

        token.merge!({ cld_id: cld_id })
        
        if token.key?('error') || !token["image"].present?
          ActionCable.server.broadcast("notifications_#{socket_id}", {
            message: 'Optimizing Error', 
            data: { cld_id: cld_id, error: "No Image Metadata Found: #{token['error']}" }
          })
          results << token
        else 
          begin
            cldResult = new(image_url: token["image"], cld_id: cld_id, socket_id: socket_id).call

            if cldResult["public_id"].present?
              # puts "Uploaded: #{cld_id}"
              ActionCable.server.broadcast("notifications_#{socket_id}", {
                message: 'Image Optimized', 
                data: { cld_id: cld_id, imageId: cldResult["public_id"] }
              })

              results << { imageId: cldResult['public_id'], cld_id: cld_id }
            else 
              # puts "Saving large upload for last: #{cld_id}"
              ActionCable.server.broadcast("notifications_#{socket_id}", {
                message: 'Image Queued', 
                data: { cld_id: cld_id, imageId: nil }
              })

              later << token
            end
          rescue => e
            puts "Error uploading image for #{cld_id}: #{e.message}"
            ActionCable.server.broadcast("notifications_#{socket_id}", {
              message: 'Optimizing Error', 
              data: { cld_id: cld_id, error: "Error Optimizating Image: #{e.message}" }
            })
            results << { fallbackImage: token['image'], cld_id: cld_id, error: "Error Optimizating Image: #{e.message}" }
          end
        end
      end
      
      optimizedResults = results.map do |result|
        if result.key?(:imageId) 
          { 
            cld_id: result[:cld_id], 
            optimized: 'True', 
            error_message: nil, 
            created_at: Time.current,
            updated_at: Time.current
          }
        else 
          { 
            cld_id: result[:cld_id],
            optimized: 'Error', 
            error_message: result[:error] || "Error Optimizating Image", 
            created_at: Time.current,
            updated_at: Time.current
          }
        end
      end

      OptimizedImage.upsert_all(optimizedResults, unique_by: :cld_id) if optimizedResults.present?

      ActionCable.server.broadcast("notifications_#{socket_id}", {
        message: 'Resizing Images', 
        data: { resizing: later.count }
      })

      later.each do |token|
        cldResult = new(image_url: token["image"], cld_id: token['cld_id'], socket_id: socket_id).call_large_image
      end

      # puts "Done Uploading #{results.count} Images, #{later.count} Resized"

      results
    end


    private

    def upload_image
      begin
        response = Cloudinary::Uploader.upload(image_url, resource_type: "auto", public_id: "#{ENV['CLOUDINARY_NFT_FOLDER']}/#{cld_id}", overwrite: true, invalidate: true)
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
        # puts "Image too large, Scaling Down: #{cld_id}"
        image_file = download_image(image_url)
        scale_image(image_file)

        cldResult = Cloudinary::Uploader.upload(
          image_file.path, 
          resource_type: "auto", 
          public_id: "#{ENV['CLOUDINARY_NFT_FOLDER']}/#{cld_id}", 
          overwrite: true,
          invalidate: true
        )
        image_file.close
        image_file.unlink # delete the temporary file
        
        ActionCable.server.broadcast("notifications_#{socket_id}", {
          message: 'Image Optimized', 
          data: { cld_id: cld_id, imageId: cldResult["public_id"] }
        })

        optimized = OptimizedImage.where(cld_id: cld_id).first_or_create
        optimized.update(optimized: "True", error_message: nil)
        # puts "Uploaded Large: #{cld_id}"
      rescue => e
        puts "Error uploading large image: #{e.message}"
        ActionCable.server.broadcast("notifications_#{socket_id}", {
          message: 'Optimizing Error', 
          data: { cld_id: cld_id, error: e.message }
        })
        optimized = OptimizedImage.where(cld_id: cld_id).first_or_create
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
