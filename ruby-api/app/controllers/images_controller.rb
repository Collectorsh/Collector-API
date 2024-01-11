# frozen_string_literal: true

class ImagesController < ApplicationController
  def upload
    params[:images].each do |image|
      next if UploadedImage.find_by(mint: image['mint'])
      UploadImageJob.perform_later(image['uri'], image['mint'])
    end
  end

  def upload_image_buffer
    image_buffer = params[:image_buffer]
    cld_id = params[:cld_id]

    unless image_buffer && cld_id
      return render json: { error: 'Missing required parameters' }, status: :bad_request
    end

    unless image_buffer.is_a?(String)
      return render json: { error: 'image_buffer must be a Base64 encoded string' }, status: :bad_request
    end

    buffer = Base64.decode64(image_buffer)

    result = Cloudinary::Uploader.upload(buffer, 
      resource_type: 'auto',
      public_id: cld_id,
      overwrite: true
    )
    render json: { public_id: result['public_id'] }, status: :ok
  rescue => e
    puts "Error uploading image: #{e.message}"
    Rails.logger.error("Error uploading image: #{e.message}")
    render json: { error: e.message }, status: :internal_server_error
  end

  def upload_single_token
    token = params[:token]
    socket_id = params[:socket_id]
    begin
      raise "No Token Mint or Image" unless token['mint'].present? && token['image'].present?

      cld_id = ImageUploadService.get_token_cld_id(token)

      optimized = OptimizedImage.where(cld_id: cld_id).first_or_create
      optimized.update(optimized: "Pending", error_message: nil)

      ImageUploadService.upload_batch([token], socket_id)
    
      render json: { completed: 1, mint: token['mint']}, status: :ok
    rescue => e
      puts "Error Omptimizing Image from Mint: #{e.message}"
      Rails.logger.error("Error Omptimizing Image from Mint: #{e.message}")
      render json: { error: 'Error Omptimizing Image from Mint' }, status: :internal_server_error
    end
  end
          
  def upload_with_tokens
    tokens = params[:tokens]
    socket_id = params[:socket_id]

    begin
      valid_tokens = tokens.select do |token|
        token[:mint].present? && token[:image].present?
      end

      puts "Uploading #{valid_tokens.count} images for #{socket_id}"
      # assign all mints to pending
      pending = valid_tokens.map do |token|
        { 
          cld_id: ImageUploadService.get_token_cld_id(token),
          # mint_address: token['mint'], #DEPRICATING, need to move all mint_address to cld_id first
          optimized: 'Pending', 
          error_message: nil, 
          created_at: Time.current,
          updated_at: Time.current
        }
      end
      OptimizedImage.upsert_all(pending, unique_by: :cld_id)

      puts"Finsihed upsert"

      batch_size = 8
      batches = valid_tokens.each_slice(batch_size).to_a

      threads = batches.map do |batch|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            ImageUploadService.upload_batch(batch, socket_id)
          end
        end
      end

      threads.each(&:join)

      render json: { completed: tokens.count}, status: :ok
    rescue => e
      puts "Error Uploading to Cloudinary with tokens: #{e.message}"
      Rails.logger.error("Error Uploading to Cloudinary with tokens: #{e.message}")
      render json: { error: 'Error Uploading to Cloudinary with tokens' }, status: :internal_server_error
    end
  end

  def upload_video
    token = params[:token]
    video_url = params[:video_url]
    puts "video_url: #{video_url}"
    
    return render json: { error: 'Missing required parameters' }, status: :bad_request unless token["mint"].present? && video_url.present?
    
    puts "Uploading video for #{token['mint']}"

    cld_id = ImageUploadService.get_token_cld_id(token)
    response = Cloudinary::Uploader.upload_large(
      video_url, 
      :resource_type => "video", 
      :public_id => "video/#{ENV['CLOUDINARY_NFT_FOLDER']}/#{cld_id}", 
      :overwrite => true, 
      :invalidate => true,
      :timeout => 240,
      :chunk_size => 3000000,
    )

    return render json: { public_id: response['public_id'] }, status: :ok
  rescue => e
    puts "Error Optimizing video: #{e.message}"
    Rails.logger.error("Error Optimizing video: #{e.message}")
    render json: { error: 'Error Optimizing video', msg: e.message }, status: :internal_server_error
  end
end

