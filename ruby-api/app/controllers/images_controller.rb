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
    render json: { error: e.message }, status: :internal_server_error
  end

  #DEPRICATING
  def upload_with_mints
    mints = params[:mints]
    socket_id = params[:socket_id]
    begin
      ActionCable.server.broadcast("notifications_#{socket_id}", {
        message: "Begining uploads for #{mints.count} images", 
      })
      puts "Uploading #{mints.count} images for #{socket_id}"
      # assign all mints to pending
      pending = mints.map do |mint|
        { 
          mint_address: mint, 
          optimized: 'Pending', 
          error_message: nil, 
          created_at: Time.current,
          updated_at: Time.current
        }
      end
      OptimizedImage.upsert_all(pending, unique_by: :mint_address)

      puts"Finsihed upsert"

      # fetch all nft metadata via hello moon (requires pagination past 1000k nfts)

      pagination_token = nil
      request_count = 0
      onChainTokens = [] 
      while request_count == 0 || pagination_token
        begin
          res = HTTParty.post("https://rest-api.hellomoon.io/v0/nft/mint_information", 
            body: { 
              nftMint: mints ,
              limit: 1000,
              paginationToken: pagination_token
            }.to_json, 
            headers: { 
              'Content-Type' => 'application/json',
              'authorization' => "Bearer #{ENV['HELLOMOON_API_KEY']}"
            } 
          )

          # You can use rescue block here to handle the error same as catch in javascript
        rescue => e
          puts e.message
        end

        if res && res["paginationToken"]
          pagination_token = res["paginationToken"]
        else
          pagination_token = nil
        end

        if res && res["data"]
          onChainTokens.concat(res["data"])
        end
        
        request_count += 1
      end
      
      puts "Got #{onChainTokens.count} onchain tokens"

      tokenMetadatas = []

      metaBatch_size = 25
      metaBatches = onChainTokens.each_slice(metaBatch_size).to_a

      metaThreads = metaBatches.map do |batch|
        Thread.new do
          batch.each do |token|
            begin
              uri = token['nftMetadataJson']['uri']
              response = HTTParty.get(uri)
              metadata = JSON.parse(response.body)

              if response.success?
                if metadata.key?('image') && metadata['image'].present?
                  tokenMetadata = token.merge(metadata)
                  if !tokenMetadata.key?('mint')
                    tokenMetadata['mint'] = tokenMetadata['nftMint'] 
                  end
                  tokenMetadatas << tokenMetadata
                else
                  puts "No Image in Metadata: #{metadata}"
                  tokenMetadatas << { mint: token["nftMint"], error: "No Image in Metadata" }
                end
              else
                puts "Error Getting Metadata from uri: #{response.code} - #{response.message}"
                tokenMetadatas << { mint: token["nftMint"], error: "Error Getting Metadata From uri" }
              end
            rescue StandardError => e
              puts "Error Getting offchain Metadata: #{e.message}"
              tokenMetadatas << { mint: token["nftMint"], error: "Error Fetching Offchain Metadata" }
            end
            
          end
        end
      end
      metaThreads.each(&:join)

      puts "tokenMetadatas: #{tokenMetadatas.count}"
    
      # # find tokens with no image
      unoptimizedTokens = tokenMetadatas.select { |token| !token.key?('image') || !token['image'].present? }
      if unoptimizedTokens.present? && unoptimizedTokens.count > 0
        # update optimized table to reflect unoptimized tokens
        unoptimzedRecords = unoptimizedTokens.map do |token|
          { 
            mint_address: token['mint'], 
            optimized: 'Error', 
            error_message: 'Error Fetching Image From Metadata', 
            created_at: Time.current,
            updated_at: Time.current
          }
        end
        puts "Updating unoptimized records: #{unoptimzedRecords.count}"
        OptimizedImage.upsert_all(unoptimzedRecords, unique_by: :mint_address)


        ActionCable.server.broadcast("notifications_#{socket_id}", {
          message: 'Image Metadata Errors', 
          data: { tokens: unoptimizedTokens , error: "Error Fetching Image From Metadata" }
        })
      end

      # smart jobs, process standard imiages in real time, large images in background
      batch_size = 10
      batches = tokenMetadatas.each_slice(batch_size).to_a

      threads = batches.map do |batch|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            ImageUploadService.upload_batch(batch, socket_id)
          end
        end
      end

      threads.each(&:join)

      render json: { completed: tokenMetadatas.count}, status: :ok
    rescue => e
      puts "Error Getting Token onchain Metadatas: #{e.message}"
      render json: { error: 'Error Getting Token Metadatas' }, status: :internal_server_error
    end
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
    
      render json: { completed: 1}, status: :ok
    rescue => e
      puts "Error Omptimizing Image from Mint: #{e.message}"
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
      render json: { error: 'Error Uploading to Cloudinary with tokens' }, status: :internal_server_error
    end
  end
end
