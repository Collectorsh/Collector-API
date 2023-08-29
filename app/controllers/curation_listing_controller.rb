class CurationListingController < ApplicationController
  before_action :get_authorized_user, only: [:submit_single_token, :submit_tokens]
  before_action :token_from_confirmed_owner, only: [:update_listing, :cancel_listing]

  def submit_tokens
    user = @authorized_user

    tokens = params[:tokens]

    puts "Submitting #{tokens.count} tokens"
    return render json: { status: 'error', msg: 'Tokens not sent' } unless !tokens.blank?

    successfull_listings = []

    tokens.each do |token| 
      owner_id = params[:owner_id] || User.find_by("public_keys LIKE ?", "%#{params[:owner_address]}%")&.id
      artist_id = params[:artist_id] || User.find_by("public_keys LIKE ?", "%#{params[:artist_address]}%")&.id
  
      listing = CurationListing.create({
        curation_id: params[:curation_id],
        owner_id: owner_id,
        artist_id: artist_id,
        mint: token['mint'],
        name: token['name'],
        owner_address: token['owner'],
        artist_address: token['creator'],
        aspect_ratio: token['aspect_ratio'], # aspectRatio added in the submitArtModal on the FE
        animation_url: token['animation_url'],
        image: token['image'],
        description: token['description'],
        is_primary_sale: !token['primary_sale_happened'],
        is_edition: token['is_edition'],
        creators: token['creators'],
      })

      if listing.errors.any?
        puts "Failed to save listing for #{token['mint']}: #{listing.errors.full_messages.join(", ")}"
      else
        successfull_listings << listing
      end
      
    end
    
    return render json: { status: 'success', msg: 'Tokens submitted', listings: successfull_listings }

  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def update_listing
    token = @authorized_listing

    return render json: { status: 'error', msg: 'Token already Sold' } unless token.listed_status != "sold"

    buy_now_price = params[:buy_now_price]
    listing_receipt = params[:listing_receipt]
    return render json: { status: 'error', msg: 'Props not sent' } unless buy_now_price && listing_receipt

    if token.update(listed_status: "listed", buy_now_price: buy_now_price, listing_receipt: listing_receipt)
      puts "curation name: #{token.curation.name}"
      puts "token price: #{token.buy_now_price}"
      ActionCable.server.broadcast("notifications_listings_#{token.curation.name}", {
        message: 'Listing Update', 
        data: { 
          mint: token.mint, 
          listed_status: token.listed_status,
          buy_now_price: token.buy_now_price,
          listing_receipt: token.listing_receipt
        }
      })
      return render json: { status: 'success', msg: 'Token listing updated' }
    else 
      puts "FAILED TO SAVE TOKEN: #{token.errors.full_messages.join(", ")}"
      return render json: { status: 'error', msg: 'Failed to update token listing' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def cancel_listing
    token = @authorized_listing

    return render json: { status: 'error', msg: 'Token already Sold' } unless token.listed_status != "sold"

    if token.update(listed_status: "unlisted", buy_now_price: nil, listing_receipt: nil)
      ActionCable.server.broadcast("notifications_listings_#{token.curation.name}", {
        message: 'Listing Update', 
        data: { 
          mint: token.mint, 
          listed_status: token.listed_status,
          buy_now_price: token.buy_now_price,
          listing_receipt: nil
        }
      })
      render json: { status: 'success', msg: 'Token listing canceled' }
    else
      render json: { status: 'error', msg: 'Failed to cancel token listing' }, status: :unprocessable_entity
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

  def token_from_confirmed_owner
    user = get_authorized_user
    token = CurationListing.includes(:curation).find_by(mint: params[:token_mint], curation_id: params[:curation_id])

    return render json: { status: 'error', msg: 'Token not found' } unless token
    return render json: { status: 'error', msg: 'Token not owned by user' } unless user.public_keys.include?(token.owner_address)

    @authorized_listing = token
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end
end