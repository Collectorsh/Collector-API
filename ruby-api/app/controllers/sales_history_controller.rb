class SalesHistoryController < ApplicationController
  before_action :get_authorized_user, except: []
  
  def record_sale
    user = @authorized_user

    listings = CurationListing.includes(:curation).where(mint: params[:token_mint])

    if listings.empty?
      puts "Listing not found for mint: #{params[:token_mint]}"
      return render json: { status: 'error', msg: 'Listing not found' }
    end
    
    artist_address = listings[0].artist_address
    artist_id = listings[0].artist_id
    mint = listings[0].mint
    name = listings[0].name
    image = listings[0].image
    is_master_edition = listings[0].is_master_edition

    buyer_address = params[:buyer_address]
    seller_address = params[:seller_address]
    buyer_id = params[:buyer_id] || (buyer_address.present? ? User.find_by("public_keys LIKE ?", "%#{buyer_address}%")&.id : nil)
    seller_id = params[:seller_id] || (seller_address.present? ? User.find_by("public_keys LIKE ?", "%#{seller_address}%")&.id : nil)
  
    editionListingUpdateFailed = false

    begin
      if is_master_edition

        listings.each do |listing|
          new_supply = listing.supply + params[:editions_minted].to_i
          status = listing.listed_status

          if listing.listed_status == "listed" && new_supply >= listing.max_supply
            status = "sold"
          end

          begin
            if listing.update(
              listed_status: status, 
              supply: new_supply
            )
              begin 
                ActionCable.server.broadcast("notifications_listings_#{listing.curation.name}", {
                  message: 'Listing Update', 
                  data: { 
                    mint: listing.mint, 
                    listed_status: listing.listed_status,
                    supply: listing.supply
                  }
                })
              rescue StandardError => e
                Rails.logger.error("Websocket Error: record_sale (ME) - notifications_listings_#{listing.curation.name}: #{e.message}")
              end
            else
              Rails.logger.error("Record Master Editions Sale error. Failed to update listing for #{listing.curation.name}: #{listing.errors.full_messages.join(", ")}")
              puts "Failed to update listing for #{listing.curation.name} Editions: #{listing.errors.full_messages.join(", ")}"
            end
          rescue ActiveRecord::StaleObjectError
            Rails.logger.error("Stale Master Edition Update. Failed to update listing for #{listing.curation.name}")
            puts "Stale Master Edition Update. Failed to update listing for #{listing.curation.name}"
            # If the listing was updated by another process let the front end know so it can update with onchian data
            editionListingUpdateFailed = true
          end
        end
        
        # update minted_indexer if found
        minted_indexer = MintedIndexer.find_by(mint: mint)

        if minted_indexer && !minted_indexer.update(supply: new_supply)
          Rails.logger.error("Record Master Editions Sale error. Failed to update minted_indexer for #{mint}: #{minted_indexer.errors.full_messages.join(", ")}")
          puts "Failed to update minted_indexer for #{mint}: #{minted_indexer.errors.full_messages.join(", ")}"
        end

      else
        # Go through all listings in case the token is listined in multiple curations
        listings.each do |listing|
          if listing.update(
            listed_status: "sold", 
            owner_address: buyer_address, 
            owner_id: buyer_id,
            primary_sale_happened: true,
            listing_receipt: nil
          )
            begin
              ActionCable.server.broadcast("notifications_listings_#{listing.curation.name}", {
                message: 'Listing Update', 
                data: { 
                  mint: listing.mint, 
                  listed_status: listing.listed_status,
                  listing_receipt: listing.listing_receipt,
                  owner_address: listing.owner_address,
                  owner_id: listing.owner_id,
                  primary_sale_happened: listing.primary_sale_happened
                }
              })
            rescue StandardError => e
              Rails.logger.error("Websocket Error: record_sale - notifications_listings_#{listing.curation.name}: #{e.message}")
            end

          else
            Rails.logger.error("Record Sale error. Failed to update listing for #{listing.curation.name}: #{listing.errors.full_messages.join(", ")}")
            puts "Failed to update listing for #{listing.curation.name}: #{listing.errors.full_messages.join(", ")}"
          end

          # update minted_indexer if found
          minted_indexer = MintedIndexer.find_by(mint: listing.mint)

          if minted_indexer && !minted_indexer.update(
            owner_address: buyer_address, 
            owner_id: buyer_id,
            primary_sale_happened: true,
          )
            Rails.logger.error("Record Sale error. Failed to update minted_indexer for #{mint}: #{minted_indexer.errors.full_messages.join(", ")}")
            puts "Failed to update minted_indexer for #{mint}: #{minted_indexer.errors.full_messages.join(", ")}"
          end
        end
      end
    rescue StandardError => e
      Rails.logger.error("Error in record sale, failed to updating listings: #{e.message}")
    end
  
    recorded_sale = SalesHistory.create(
      curation_id: params[:curation_id],
      price: params[:price],
      is_primary_sale: params[:is_primary_sale],
      sale_type: params[:sale_type],
      tx_hash: params[:tx_hash],
      editions_minted: params[:editions_minted],
      token_mint: mint,
      token_name: name,
      buyer_id: buyer_id,
      buyer_address: buyer_address,
      seller_id: seller_id,
      seller_address: seller_address,
      artist_id: artist_id,
      artist_address: artist_address,
    )

    if recorded_sale.errors.any?
      Rails.logger.error("Failed to save recorded sale: #{recorded_sale.errors.full_messages.join(", ")}")
      puts "Failed to save recorded sale: #{recorded_sale.errors.full_messages.join(", ")}"
      return render json: { status: 'error', msg: "Failed to save sale history" }, status: :unprocessable_entity
    else
      return render json: { status: 'success', msg: 'Token sale recorded', editionListingUpdateFailed: editionListingUpdateFailed }
    end
  rescue StandardError => e
    # Rails.logger.error("Error recording sale: #{e.message}")
    # Rails.logger.error(e.backtrace.join("\n"))
    Rails.logger.error(["Error recording sale: #{e.message} - Backtrace: ", *e.backtrace].join("$/"))

    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_by_range
    artist_username = params[:artist_username]
    buyer_username = params[:buyer_username]
    curation_name = params[:curation_name]

    artist = artist_username.present? ? User.find_by(username: artist_username) : nil
    buyer = buyer_username.present? ? User.find_by(username: buyer_username) : nil
    curation = curation_name.present? ? Curation.find_by(name: curation_name) : nil

    records = SalesHistory
      .includes(:buyer, :seller, :artist, curation: :curator)
      .where("created_at >= ? AND created_at <= ?", params[:start_date], params[:end_date])
      .order(created_at: :desc)

    records = records.where(artist_id: artist.id) if artist.present?
    records = records.where(buyer_id: buyer.id) if buyer.present?
    records = records.where(curation_id: curation.id) if curation.present?

    modified_records = records.map do |record|
      {
        **record.attributes.symbolize_keys,
        buyer: record.buyer&.public_info,
        seller: record.seller&.public_info,
        artist: record.artist&.public_info,
        curation: record.curation&.basic_info,
      }
    end

    render json: modified_records
  rescue StandardError => e
    Rails.logger.error("Error getting sales history: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  private 
  
  def get_authorized_user
    return render json: { status: 'error', msg: 'Auth missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])

    return render json: { status: 'error', msg: 'Api key not valid' } unless user

    @authorized_user = user
  end
end