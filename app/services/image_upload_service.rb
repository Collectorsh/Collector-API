  class ImageUploadService
    require 'open-uri'
    require 'tempfile'
    require 'mini_magick'

    MAX_FILE_SIZE = 20 * 1000 * 1000 # 20 MB

    attr_reader :image_url, :mint

    def initialize(image_url:, mint:)
      @image_url = image_url
      @mint = mint
    end

    def call
      upload_image
    end

    def self.upload_batch(tokens)
      results = []
      tokens.each do |token|
        # skip if no mint
        next unless token.key?('mint') && token['mint'].present?

        if token.key?('error') || !token.key?('image')
          optimized = OptimizedImage.where(mint_address: token["mint"]).first_or_create
          optimized.update(optimized: "Error", error_message: "No Image Metadata Found: #{token['error']}")
          results << token
        else 
          begin
            cldResults = new(image_url: token["image"], mint: token["mint"]).call

            puts "uploaded: #{cldResults["public_id"]}"

            optimized = OptimizedImage.where(mint_address: token["mint"]).first_or_create
            optimized.update(optimized: "True", error_message: nil)

            results << { imageId: cldResults["public_id"], mint: token["mint"] }
          rescue => e
            Rails.logger.error "#{token["mint"]}: #{e.message}"
            puts "Error uploading image for mint #{token["mint"]}: #{e.message}"
            optimized = OptimizedImage.where(mint_address: token["mint"]).first_or_create
            optimized.update(optimized: "Error", error_message: "Error Optimizing: #{e.message}")
            results << { fallbackImage: token["image"], mint: token["mint"], error: "Error Optimizating Image" }
          end
        end
      end

      results
    end

    private

    def upload_image
      begin
        puts "Uploading image: #{mint}"
        response = Cloudinary::Uploader.upload(image_url, resource_type: "auto", public_id: "#{ENV['CLOUDINARY_NFT_FOLDER']}/#{mint}", overwrite: true)
        response
      rescue => e
        if e.message.include?("File size too large")
          puts "Image too large, scaling down: #{mint}"
          image_file = download_image(image_url)
          scale_image(image_file)
          response = Cloudinary::Uploader.upload(image_file.path, resource_type: "auto", public_id: "#{ENV['CLOUDINARY_NFT_FOLDER']}/#{mint}", overwrite: true)
          image_file.close
          image_file.unlink  # delete the temporary file
          response
        else
          raise
        end
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
      image = MiniMagick::Image.open(image_file.path)
      image.resize("#{2000}x")
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
