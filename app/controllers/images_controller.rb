# frozen_string_literal: true

class ImagesController < ApplicationController
  def upload
    params[:images].each do |image|
      next if UploadedImage.find_by(mint: image['mint'])
      UploadImageJob.perform_later(image['uri'], image['mint'])
    end
  end

  def upload_with_mints
    mints = params[:mints]
    username = params[:username]
    begin

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
      puts "pending: #{pending}"
      OptimizedImage.upsert_all(pending, unique_by: :mint_address)

      response = HTTParty.post("https://rest-api.hellomoon.io/v0/nft/mint_information", 
        body: { nftMint: mints }.to_json, 
        headers: { 
          'Content-Type' => 'application/json',
          'authorization' => "Bearer #{ENV['HELLOMOON_API_KEY']}"
        } 
      )
      onChainTokens = response['data']

      tokenMetadatas = []
      onChainTokens.each do |token|
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

     

      # find tokens with no image
      # unoptimizedTokens = tokenMetadatas.select { |token| !token.key?('image') || !token['image'].present? }

      # # update optimized table to reflect unoptimized tokens
      # unoptimzedRecords = unoptimizedTokens.map do |token|
      #   { mint_address: token['mint'], optimized: 'Error', error_message: 'Error Fetching Image From Metadata' }
      # end
      # puts "Unoptimized Records: #{unoptimzedRecords}"
      # OptimizedImage.upsert_all(unoptimzedRecords, unique_by: :mint_address) if unoptimzedRecords.present?
      # puts "about to broadcast"
      # ActionCable.server.broadcast("notifications_channel_#{username}", {
      #   message: 'Image Metadata Errors', 
      #   data: { tokens: unoptimizedTokens , error: "Error Fetching Image From Metadata" }
      # })

      # Start jobs for tokens with images
       # (TODO: once async workers are set up switch to permorm_later)
      # tokenMetadatas.each do |tokenMetadata|
      #   if tokenMetadata.key?('image') && tokenMetadata['image'].present?
      #     puts "Starting job for #{tokenMetadata["mint"]}"
      #     OptimizeImageJob.perform_now(tokenMetadata["image"], tokenMetadata["mint"], username)
      #   end
      # end
      
      # render status: :ok

      # use mint and image from meta data to call upload_cloudinary_batch
      cloudinaryImages = ImageUploadService.upload_batch(tokenMetadatas)
      render json: cloudinaryImages, status: :ok
    rescue => e
      puts "Error Getting Token onchain Metadatas: #{e.message}"
      render json: { error: 'Error Getting Token Metadatas' }, status: :internal_server_error
    end
  end

  def upload_with_tokens() 
    tokens = params[:tokens]
    username = params[:username]

    begin
      # start jobs (TODO: once async workers are set up switch to permorm_later)
      tokens.each do |token|
        if token.key?('image') && token['image'].present && token['mint'].present?
          OptimizeImageJob.perform_now(token["image"], token["mint"], username)
        else
          puts "No Image in Token: #{token}"
        end
      end
      unoptimized = tokens.select { |token| !token.key?('image') || !token['image'].present? }
      render json: unoptimized, status: :ok


      cloudinaryImages =  ImageUploadService.upload_batch(tokens)
      render json: cloudinaryImages, status: :ok
    rescue => e
      puts "Error Uploading to Cloudinary with token: #{e.message}"
      render json: { error: 'Error Uploading to Cloudinary with token' }, status: :internal_server_error
    end
  end

end

