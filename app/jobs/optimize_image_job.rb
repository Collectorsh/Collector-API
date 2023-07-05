# frozen_string_literal: true

class OptimizeImageJob < ApplicationJob
  queue_as :imageOptimize

  def priority
    11
  end

  def perform(image, mint, username)
    return unless image && mint && username

    puts "Optimizing token #{mint} with Image: #{image}"
    cldResult = ImageUploadService.new(image_url: image, mint: mint).call

    #send websocket message
    ActionCable.server.broadcast("notifications_channel_#{username}", {
      message: 'Image Optimized', 
      data: { mint: mint, imageId: cldResult["public_id"] }
    })
    Rails.logger.debug "image optimized"
    optimized = OptimizedImage.where(mint_address: mint).first_or_create
    optimized.update(optimized: "True", error_message: nil)
  rescue StandardError => e
    puts "Error in Optimizing Job: #{e.message}"
    Bugsnag.notify(e)
    optimized = OptimizedImage.where(mint_address: mint).first_or_create
    optimized.update(optimized: "Error", error_message: "Error Optimizing: #{e.message}")

    ActionCable.server.broadcast("notifications_channel_#{username}", {
      message: 'Optimizing Error', 
      data: { mint: mint, error: e.message }
    })
  end
end
