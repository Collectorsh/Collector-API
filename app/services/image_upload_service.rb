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
      begin
        cldResults = new(image_url: token["image"], mint: token["mint"]).call
        puts "uploaded: #{cldResults["public_id"]}"
        results << { id: cldResults["public_id"], mint: token["mint"] }
      rescue => e
        Rails.logger.error "#{token["mint"]}: #{e.message}"
        puts "Error uploading image for mint #{token["mint"]}: #{e.message}"
        results << { fallbackImage: token["image"], mint: token["mint"] }
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

    target_size = MAX_FILE_SIZE
    max_iterations = 10
    iteration = 0
    min_width = 0
    max_width = image.width
    width = image.width

    while image.size > target_size && iteration < max_iterations && min_width < max_width
      width = (min_width + max_width) / 2
      image.resize("#{width}x")

      if image.size > target_size
        max_width = width - 1
      else
        min_width = width + 1
      end

      iteration += 1
    end

    image.write(image_file.path)

  end
end