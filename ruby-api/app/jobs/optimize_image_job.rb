# frozen_string_literal: true

class OptimizeImageJob < ApplicationJob
  queue_as :imageOptimize

  def priority
    1
  end

  def perform(image, mint, socket_id)
    # return unless image && mint && socket_id
    puts "runing optimization job for #{mint}"
    ImageUploadService.new(image_url: image, mint: mint, socket_id: socket_id).call_large_image

  rescue StandardError => e
    puts "Error in Optimizing Job: #{e.message}"
  end
end
