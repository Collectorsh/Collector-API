class SalesHistoryController < ApplicationController
  before_action :get_authorized_user, except: []
  
  def record_sale
    user = @authorized_user

    buyer_id = params[:buyer_id] || User.find_by("public_keys LIKE ?", "%#{params[:buyer_address]}%")&.id
    seller_id = params[:seller_id] || User.find_by("public_keys LIKE ?", "%#{params[:seller_address]}%")&.id
    artist_id = params[:artist_id] || User.find_by("public_keys LIKE ?", "%#{params[:artist_address]}%")&.id

    listings = CurationListing.where(mint: params[:token_mint])
    
    if listings.empty?
      return render json: { status: 'error', msg: 'Listing not found' }
    end

    # Go through all listings in case the token is listined in multiple curations
    listings.each do |listing|
      if listing.update(
        listed_status: "sold", 
        buy_now_price: nil, 
        owner_address: params[:buyer_address], 
        owner_id: buyer_id,
        is_primary_sale: false,
        listing_receipt: nil
      )
        ActionCable.server.broadcast("notifications_listings_#{listing.curation.name}", {
          message: 'Listing Update', 
          data: { 
            mint: listing.mint, 
            listed_status: listing.listed_status,
            buy_now_price: listing.buy_now_price,
            listing_receipt: listing.listing_receipt
          }
        })
      else
        puts "Failed to update listing for #{listing.curation.name}: #{listing.errors.full_messages.join(", ")}"
      end
    end
  
    recorded_sale = SalesHistory.create(
      curation_id: params[:curation_id],
      price: params[:price],
      is_primary_sale: params[:is_primary_sale],
      sale_type: params[:sale_type],
      tx_hash: params[:tx_hash],
      token_mint: listings[0].mint,
      token_name: listings[0].name,
      buyer_id: buyer_id,
      buyer_address: params[:buyer_address],
      seller_id: seller_id,
      seller_address: params[:seller_address],
      artist_id: artist_id,
      artist_address: params[:artist_address],
    )

    if recorded_sale.errors.any?
      puts "Failed to save recorded sale: #{recorded_sale.errors.full_messages.join(", ")}"
      return render json: { status: 'error', msg: "Failed to save sale history" }, status: :unprocessable_entity
    else
      return render json: { status: 'success', msg: 'Token sale recorded' }
    end
  rescue StandardError => e
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