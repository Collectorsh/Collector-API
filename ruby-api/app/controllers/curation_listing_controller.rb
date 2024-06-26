class CurationListingController < ApplicationController
  before_action :get_authorized_user, only: [:submit_single_token, :submit_tokens, :delete_multiple_submissions, :update_edition_supply, :update_listing_status]
  before_action :token_from_confirmed_owner, only: [:update_listing, :cancel_listing, :delete_submission]

  def submit_tokens
    user = @authorized_user

    tokens = params[:tokens]

    return render json: { status: 'error', msg: 'Tokens not sent' } unless !tokens.blank?
    puts "Submitting #{tokens.count} tokens"

    successfull_listings = []
    errors = []

    tokens.each do |token| 

      is_master_edition = token['is_master_edition']

      owner_address = token['owner_address']
      artist_address = token['artist_address']
      owner_id = params[:owner_id] || (owner_address.present? ? User.find_by("public_keys LIKE ?", "%#{owner_address}%")&.id : nil)
      artist_id = params[:artist_id] || (artist_address.present? ? User.find_by("public_keys LIKE ?", "%#{artist_address}%")&.id : nil)

      temp_artist_name = nil
      if token["artist_name"].present?
        temp_artist_name = token["artist_name"]
      elsif artist_id.nil? && artist_address.present? 
        begin
          url = "https://api.mallow.art/users/#{artist_address}"
          headers = {
            "X-Api-Key" => ENV['MALLOW_API_KEY'],
          }

          response = HTTParty.get(url, headers: headers)

          # Check if parsed_response and result key exist
          parsed_response = response.parsed_response
          if parsed_response && parsed_response["result"]
            result = parsed_response["result"]

            # Access the displayName and username properties
            display_name = result["displayName"]
            username = result["username"]

            temp_artist_name = display_name || username
          end

        rescue StandardError => e
          Rails.logger.error("Error fetching artist name from mallow api: #{e.message}")
        end
      end
  
      listing = CurationListing.create({
        curation_id: params[:curation_id],
        owner_id: owner_id,
        artist_id: artist_id,
        mint: token['mint'],
        name: token['name'],
        owner_address: owner_address,
        artist_address: artist_address,
        aspect_ratio: token['aspect_ratio'], # aspectRatio added in the submitArtModal on the FE
        animation_url: token['animation_url'],
        image: token['image'],
        description: token['description'],
        creators: token['creators'],
        primary_sale_happened: token['primary_sale_happened'],
        is_edition: token['is_edition'],
        is_master_edition: is_master_edition,
        supply: token['supply'],
        parent: token['parent'],
        max_supply: token['max_supply'],
        files: token['files'],
        temp_artist_name:  temp_artist_name,
        compressed: token['compressed'],
      })

      if listing.errors.any?
        errors << { mint: token['mint'], message: "Failed to submit: #{token['mint']}"}
        Rails.logger.error("Failed to save listing for #{token['mint']}: #{listing.errors.full_messages.join(", ")}")
        puts "Failed to save listing for #{token['mint']}: #{listing.errors.full_messages.join(", ")}"
      else
        successfull_listings << listing
      end
      
    end
    
    return render json: { status: 'success', listings: successfull_listings, errors: errors }

  rescue StandardError => e
    # Rails.logger.error "Error submitting tokens: #{e.message}"
    Rails.logger.error(["Error submitting tokens: #{e.message} - Backtrace: ", *e.backtrace].join("$/"))
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def delete_submission
    token = @authorized_listing

    unless token.listed_status != "listed"
      return render json: { status: 'error', msg: 'Token is listed' }
    end

    if token.destroy
      render json: { status: 'success', msg: 'Token submission deleted' }
    else
      render json: { status: 'error', msg: 'Failed to delete token submission' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error("Error deleting submission: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def delete_multiple_submissions

    user = @authorized_user;
    token_mints = params[:token_mints]
    curation_id = params[:curation_id]

    if token_mints.blank? || !curation_id.present?
      return render json: { status: 'error', msg: 'missing parameters' }, status: :unprocessable_entity
    end

    # get all tokens requested expect when they are already listed
    tokens = CurationListing.where(
      mint: token_mints, 
      owner_id: user.id, 
      curation_id: curation_id,
    ).where.not(listed_status: 'listed')

    if tokens.exists? 
      
      tokens.destroy_all
      
      render json: { status: 'success', msg: 'Token submissions deleted' }
    else
      render json: { status: 'error', msg: 'Failed to delete token submissions' }
    end
  rescue StandardError => e
    Rails.logger.error("Error deleting submissions: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def update_listing_metadata
    token = params[:token]

    return render json: { status: 'error', msg: 'Token not found' } unless token

    listings = CurationListing.where(mint: token['mint'])

    owner_address = token['owner_address']
    artist_address = token['artist_address']
    owner_id = params[:owner_id] || (owner_address.present? ? User.find_by("public_keys LIKE ?", "%#{owner_address}%")&.id : nil)
    artist_id = params[:artist_id] || (artist_address.present? ? User.find_by("public_keys LIKE ?", "%#{artist_address}%")&.id : nil)
  
    if listings.update_all(
      owner_id: owner_id,
      artist_id: artist_id,
      name: token['name'],
      owner_address: owner_address,
      artist_address: artist_address,
      aspect_ratio: token['aspect_ratio'], # aspectRatio added in the submitArtModal on the FE
      animation_url: token['animation_url'],
      image: token['image'],
      description: token['description'],
      creators: token['creators'],
      primary_sale_happened: token['primary_sale_happened'],
      is_edition: token['is_edition'],
      is_master_edition: token['is_master_edition'],
      supply: token['supply'],
      parent: token['parent'],
      max_supply: token['max_supply'],
      files: token['files']
    ) 
      render json: { status: 'success', msg: 'Token listing updated' }
    else
      Rails.logger.error("Failed to update listing metadata for #{token['mint']}: #{listings.errors.full_messages.join(", ")}")
      render json: { status: 'error', msg: 'Failed to update token listing' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error("Error updating listing metadata: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def update_edition_supply
    user = @authorized_user # just using to confirm action comes from a valid user

    token = params[:token]
    supply = params[:supply]

    return render json: { status: 'error', msg: 'No params sent' } unless token && supply
    
    listings = CurationListing.includes(curation: [:curator]).where(mint: token['mint'])
    
    return render json: { status: 'error', msg: 'Listing not found' } unless listings

    #active listing where master_edition_market_address matches token['master_edition_market_address']
    main_listing = listings.find { |l| l.master_edition_market_address == token['master_edition_market_address'] } || listings[0].listed_status

    status = main_listing.listed_status 

    if main_listing.listed_status == "listed" && supply >= main_listing.max_supply
      status = "sold"
    end

    listings.each do |listing|
      begin
        if listing.update(supply: supply, listed_status: status)
          begin
            ActionCable.server.broadcast("notifications_listings_#{listing.curation.curator.username}-#{listing.curation.name}", {
              message: 'Listing Update', 
                data: { 
                  mint: listing.mint, 
                  listed_status: listing.listed_status,
                  supply: listing.supply
                }
              }
            )
          rescue StandardError => e
            Rails.logger.error("Websocket Error: update_edition_supply - notifications_listings_#{token.curation.name}: #{e.message}")
          end
        else
          raise listing.errors.full_messages.join(", ")
        end
      rescue ActiveRecord::StaleObjectError
        Rails.logger.error("Stale Master Edition Update. Failed to update edition supply  #{main_listing.mint}")
      rescue StandardError => e
        Rails.logger.error("Failed to update update edition supply for #{main_listing.mint}: #{listing.errors.full_messages.join(", ")}")
      end
    end

    #update minted_indexer if found
    begin
      minted_indexer = MintedIndexer.find_by(mint: main_listing.mint)
      if minted_indexer && !minted_indexer.update(supply: supply)
        raise minted_indexer.errors.full_messages.join(", ")
      end
    rescue StandardError => e
      Rails.logger.error("Failed to update minted_indexer for #{main_listing.mint}: #{e.message}")
    end

    render json: { status: 'success', msg: 'Edition supply updated', listed_status: status }
  rescue StandardError => e
    Rails.logger.error("Error updating edition supply: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end


  def update_listing_status
    user = @authorized_user # just using to confirm action comes from a valid user

    token = CurationListing.includes(curation: [:curator]).find_by(mint: params[:token_mint], curation_id: params[:curation_id])

    if !token.present?
      return render json: { status: 'error', msg: 'Token not found' }
    end

    owner_address = params[:owner_address]
    owner_id = params[:owner_id] || (owner_address.present? ? User.find_by("public_keys LIKE ?", "%#{owner_address}%")&.id : nil)

    if token.update(
      owner_id: owner_id,
      owner_address: owner_address,
      listed_status: params[:listed_status], 
      nft_state: params[:nft_state]
    )
      begin
        ActionCable.server.broadcast("notifications_listings_#{token.curation.curator.username}-#{token.curation.name}", {
          message: 'Listing Update', 
          data: { 
            mint: token.mint, 
            listed_status: token.listed_status,
            owner_address: token.owner_address,
            nft_state: token.nft_state
          }
        })
      rescue StandardError => e
        Rails.logger.error("Websocket Error: update_listing_status - notifications_listings_#{token.curation.name}: #{e.message}")
      end

      #if this is a collector listing, also update associated listings in artist curations
      begin
        if token.curation.curation_type == "collector"
          artistListings = CurationListing.includes(:curation)
                                      .where(curation: { curation_type: "artist" })
                                      .where(mint: token.mint)

          artistListings.each do |artistListing|
            unless artistListing.update(
              listed_status: params[:listed_status], 
              owner_id: owner_id,
              owner_address: owner_address,
              nft_state: params[:nft_state]
            )
              Rails.logger.error("Failed to update artist listing for #{artistListing.mint}: #{artistListing.errors.full_messages.join(", ")}")
            end
          end
        end
      rescue StandardError => e
        Rails.logger.error("Error fetching listings with artist curations: #{e.message}")
      end

      render json: { status: 'success', msg: 'Token listing status updated' }
    else
      Rails.logger.error("Failed to update listing status for #{token.mint}: #{token.errors.full_messages.join(", ")}")
      render json: { status: 'error', msg: 'Failed to update token listing status' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error("Error updating listing status: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end


  def update_listing
    token = @authorized_listing

    return render json: { status: 'error', msg: 'Token already Sold' } unless token.listed_status != "sold"

    buy_now_price = params[:buy_now_price]
    listing_receipt = params[:listing_receipt]
    master_edition_market_address = params[:master_edition_market_address]

    has_required_props = token.is_master_edition ? master_edition_market_address.present? : listing_receipt.present?
    if !has_required_props || !buy_now_price.present?
      Rails.logger.error("Missing required props #{token.mint}: ME market address#{master_edition_market_address}, listing reciept: #{listing_receipt}, buy now price: #{buy_now_price}")
      return render json: { status: 'error', msg: 'Props not sent' }
    end

    if token.update(
      listed_status: "listed", 
      buy_now_price: buy_now_price, 
      listing_receipt: listing_receipt,
      master_edition_market_address: master_edition_market_address
    )
      begin
        ActionCable.server.broadcast("notifications_listings_#{token.curation.curator.username}-#{token.curation.name}", {
          message: 'Listing Update', 
          data: { 
            mint: token.mint, 
            listed_status: token.listed_status,
            buy_now_price: token.buy_now_price,
            listing_receipt: token.listing_receipt,
            master_edition_market_address: token.master_edition_market_address
          }
        })
      rescue StandardError => e
        Rails.logger.error("Websocket Error: update_listing - notifications_listings_#{token.curation.name}: #{e.message}")
      end

      #if this is a collector listing, also update associated listings in artist curations
      begin
        if token.curation.curation_type == "collector"
          artistListings = CurationListing.includes(:curation)
                                      .where(curation: { curation_type: "artist" })
                                      .where(mint: token.mint)

          artistListings.each do |artistListing|
            unless artistListing.update(
              listed_status: "listed", 
              buy_now_price: buy_now_price, 
              listing_receipt: listing_receipt,
              # master_edition_market_address not needed cause wont be in artist listings
            )
              Rails.logger.error("Failed to update artist listing for #{artistListing.mint}: #{artistListing.errors.full_messages.join(", ")}")
            end
          end
        end
      rescue StandardError => e
        Rails.logger.error("Error fetching listings with artist curations: #{e.message}")
      end

      return render json: { status: 'success', msg: 'Token listing updated' }
    else 
      Rails.logger.error("Failed to update listing for #{token.mint}: #{token.errors.full_messages.join(", ")}")
      return render json: { status: 'error', msg: 'Failed to update token listing' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error(["Error updating listing: #{e.message} - Backtrace: ", *e.backtrace].join("$/"))
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def cancel_listing
    token = @authorized_listing

    if token.is_master_edition
      status = token.supply >= token.max_supply ? "master-edition-closed" : "unlisted"
      if token.update(listed_status: status, primary_sale_happened: true)

        begin
          ActionCable.server.broadcast("notifications_listings_#{token.curation.curator.username}-#{token.curation.name}", {
            message: 'Listing Update', 
            data: { 
              mint: token.mint, 
              listed_status: token.listed_status,
              buy_now_price: token.buy_now_price,
              primary_sale_happened: token.primary_sale_happened
            }
          })
        rescue StandardError => e
          Rails.logger.error("Websocket Error: cancel_listing (ME) - notifications_listings_#{token.curation.name}: #{e.message}")
        end
        
        render json: { status: 'success', msg: 'Master Edition listing canceled' }
      else
        Rails.logger.error("Failed to cancel Master Edition listing for #{token.mint}: #{token.errors.full_messages.join(", ")}")
        render json: { status: 'error', msg: 'Failed to cancel Master Edition listing' }, status: :unprocessable_entity
      end

      #update minted_indexer if found (a master editions "primary sale" is finished as soon as the master edition is withdrawn /sale is closed)
      minted_indexer = MintedIndexer.find_by(mint: token.mint)
      if minted_indexer && !minted_indexer.update(primary_sale_happened: true)
        puts "Failed to update minted_indexer for #{token.mintt}: #{minted_indexer.errors.full_messages.join(", ")}"
        Rails.logger.error("Failed to update minted_indexer for #{token.mint}: #{minted_indexer.errors.full_messages.join(", ")}")
      end

    else
      return render json: { status: 'error', msg: 'Token already Sold' } unless token.listed_status != "sold"

      if token.update(listed_status: "unlisted", buy_now_price: nil, listing_receipt: nil)
        begin
          ActionCable.server.broadcast("notifications_listings_#{token.curation.curator.username}-#{token.curation.name}", {
            message: 'Listing Update', 
            data: { 
              mint: token.mint, 
              listed_status: token.listed_status,
              buy_now_price: token.buy_now_price,
              listing_receipt: nil
            }
          })
        rescue StandardError => e
          Rails.logger.error("Websocket Error: cancel_listing - notifications_listings_#{token.curation.name}: #{e.message}")
        end

        #if this is a collector listing, also update associated listings in artist curations
        begin
          if token.curation.curation_type == "collector"
            artistListings = CurationListing.includes(:curation)
                                        .where(curation: { curation_type: "artist" })
                                        .where(mint: token.mint)

            artistListings.each do |artistListing|
              unless artistListing.update(listed_status: "unlisted", buy_now_price: nil, listing_receipt: nil)
                Rails.logger.error("Failed to cancel artist listing for #{artistListing.mint}: #{artistListing.errors.full_messages.join(", ")}")
              end
            end
          end
        rescue StandardError => e
          Rails.logger.error("Error fetching listings to cancel with artist curations: #{e.message}")
        end

        render json: { status: 'success', msg: 'Token listing canceled' }
      else
        Rails.logger.error("Failed to cancel listing for #{token.mint}: #{token.errors.full_messages.join(", ")}")
        render json: { status: 'error', msg: 'Failed to cancel token listing' }, status: :unprocessable_entity
      end
    end
  rescue StandardError => e
    Rails.logger.error(["Error canceling listing: #{e.message} - Backtrace: ", *e.backtrace].join("$/"))
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_listed_item
    token = CurationListing.includes(:curation).find_by(mint: params[:token_mint], listed_status: "listed")
    if token
      render json: { status: 'success', token: token, curationName: token.curation.name }
    else
      render json: { status: 'error', msg: 'Token not found' }
    end
  rescue StandardError => e
    Rails.logger.error("Error getting listed item: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_listings_by_parent
    listings = CurationListing.includes(:curation).where(parent: params[:parent], listed_status: "listed")
    # include full curation with listings
    listings = listings.map do |listing| 
      curation = listing.curation.condensed
      
      listing = listing.as_json

      listing['curation'] = curation

      listing
    end
    
    if listings
      render json: { status: 'success', listings: listings}
    else
      render json: { status: 'error', msg: 'Listings not found' }
    end
  rescue StandardError => e
    Rails.logger.error("Error getting listings by parent: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  private 
  
  def get_authorized_user
    return render json: { status: 'error', msg: 'Auth missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user 

    @authorized_user = user
  end

  def token_from_confirmed_owner
    user = get_authorized_user
    token = CurationListing.includes(curation: [:curator]).find_by(mint: params[:token_mint], curation_id: params[:curation_id])


    if !token.present?
      puts "Token not found: #{params[:token_mint]}"
      return render json: { status: 'error', msg: 'Token not found' }
    end

    if !user.present? || !user.public_keys.include?(token.owner_address)
      puts "Token not owned by user: #{token.mint}"
      return render json: { status: 'error', msg: 'Token not owned by user' }
    end

    @authorized_listing = token
  rescue StandardError => e
    Rails.logger.error("Error getting token from confirmed owner: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end
end