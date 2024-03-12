# frozen_string_literal: true

require 'aws-sdk-s3'
require 'down'
require 'httparty'
require 'marcel'

class UploadImageJob < ApplicationJob
  queue_as :image

  def priority
    10
  end

  def perform(uri, mint)
    return unless uri && mint

    filename = mint.to_s
    cdn_url = "https://cdn.collector.sh/#{filename}"
    Rails.logger.debug "CDN URL: #{cdn_url}"

    return if remote_file_exists(cdn_url)

    image_url = uri

    tempfile = Down.download(image_url)
    Rails.logger.debug "file downloaded"

    file = File.open(tempfile.path)

    mime = Marcel::MimeType.for file
    Rails.logger.debug "mime type detected: #{mime}"

    unless mime == 'image/gif'
      begin
        image = Rszr::Image.load(tempfile.path)
        image = if image.width > image.height
                  image.resize(1000, :auto)
                else
                  image.resize(:auto, 1000)
                end

        image.save(tempfile.path)
      rescue StandardError => e
        Rails.logger.error e.message
      end
    end

    file = File.open(tempfile.path)

    client.put_object({
                        bucket: "cdn.collector.sh",
                        key: filename,
                        body: file,
                        acl: "public-read",
                        content_type: mime
                      })
    Rails.logger.debug "image uploaded"

    FileUtils.rm tempfile.path
    upload = UploadedImage.where(mint: mint).first_or_create
    upload.update_attribute(:success, true)
  rescue StandardError => e
    # Bugsnag.notify(e)
    upload = UploadedImage.where(mint: mint).first_or_create
    upload.update_attribute(:retries, upload.retries + 1)
  end

  def client
    Aws::S3::Client.new(
      access_key_id: ENV['S3_ACCESS_KEY_ID'],
      secret_access_key: ENV['S3_SECRET_ACCESS_KEY'],
      endpoint: ENV['S3_ENDPOINT'],
      region: ENV['S3_REGION']
    )
  end

  def remote_file_exists(url)
    url_parsed = URI(url)
    response = nil
    Net::HTTP.start(url_parsed.host, 80) do |http|
      response = http.head(url_parsed.path.to_s + url_parsed.query.to_s)
    end
    Rails.logger.debug "Check if exists: #{response.code}"
    return true if response.code[0, 1] == "2" || response.code[0, 1] == "3"

    false
  end
end
