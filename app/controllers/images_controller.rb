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
    begin
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
            end
          else
            puts "Error Getting onchain Metadata: #{response.code} - #{response.message}"
          end
        rescue StandardError => e
          puts "Error Getting offchain Metadata: #{e.message}"
          tokenMetadatas << { mint: token["nftMint"], error: "Error Fetching Offchain Metadata" }
        end
      end

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

    #tokens need "mint" and "image" keys"
    begin
      cloudinaryImages =  ImageUploadService.upload_batch(tokens)
      render json: cloudinaryImages, status: :ok
    rescue => e
      puts "Error Uploading to Cloudinary with token: #{e.message}"
      render json: { error: 'Error Uploading to Cloudinary with token' }, status: :internal_server_error
    end
  end

end

