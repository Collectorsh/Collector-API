class ImageUploadService
  require 'open-uri'
  require 'tempfile'
  require 'mini_magick'
  # require 'vips'

  MAX_FILE_SIZE = 20 * 1000 * 1000 # 20 MB
  SCALE_FACTOR = 0.9

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
    # //TODO look into thread splitting here
    tokens.each do |token|
      begin
        cldResults = new(image_url: token["image"], mint: token["mint"]).call
        puts "uploaded: #{cldResults["public_id"]}"
        results << { id: cldResults["public_id"], mint: token["mint"] }
      rescue => e
        puts "Error uploading image for mint #{token["mint"]}: #{e.message}"
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

    while image.size > MAX_FILE_SIZE
      width = (image.width * SCALE_FACTOR).round
      image.resize("#{width}x")
    end

    image.write(image_file.path)  # overwrite the original file with the scaled image

    # image = Vips::Image.new_from_file(image_file.path)
    # if image_file.size > MAX_FILE_SIZE
    #   low = 0.0
    #   high = 1.0

    #   while high - low > 0.01  # Stop when the difference between high and low is less than 1%
    #     mid = (high + low) / 2.0

    #     temp_image = image.resize(mid)  # Resize the image with the mid scale factor
    #     temp_file = Tempfile.new('temp_image')
    #     temp_image.write_to_file(temp_file.path)

    #     if temp_file.size > MAX_FILE_SIZE
    #       high = mid  # If the temp file size is greater than the maximum allowable size, decrease the high scale factor to mid
    #     else
    #       low = mid  # If the temp file size is less than or equal to the maximum allowable size, increase the low scale factor to mid
    #     end

    #     temp_file.close
    #     temp_file.unlink  # Delete the temporary file
    #   end

    #   image = image.resize(low)  # Resize the image with the low scale factor
    #   image.write_to_file(image_file.path)  # Overwrite the original file with the scaled image
    # end
  end
end