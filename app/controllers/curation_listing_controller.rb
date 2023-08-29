class CurationListingController < ApplicationController
  before_action :get_authorized_user, only: [:submit_token]
  before_action :token_from_confirmed_owner, only: [:update_listing, :cancel_listing]

  def submit_single_token
    user = @authorized_user

    token_mint = params[:token_mint]

    return render json: { status: 'error', msg: 'Wrong route for edition tokens' } unless !params[:is_edition]

    puts "submitting token_mint: #{token_mint}"
    return render json: { status: 'error', msg: 'Token mint not sent' } unless token_mint

    curation = Curation.find_by(id: params[:curation_id])
    return render json: { status: 'error', msg: 'Curation not found' } unless curation

    required_params = [
      params[:name], 
      params[:aspect_ratio], 
      params[:artist_address], 
      params[:owner_address], 
    ]
    return render json: { status: 'error', msg: 'Missing required params to create a new listed token' } unless required_params.none?(&:blank?)

    owner_id = params[:owner_id] || User.find_by("public_keys LIKE ?", "%#{params[:owner_address]}%")&.id
    artist_id = params[:artist_id] || User.find_by("public_keys LIKE ?", "%#{params[:artist_address]}%")&.id

    listing = CurationListing.create({
      mint: token_mint,
      curation_id: params[:curation_id],
      name: params[:name],
      owner_id: owner_id,
      owner_address: params[:owner_address],
      artist_id: artist_id,
      artist_address: params[:artist_address],
      aspect_ratio: params[:aspect_ratio],
      animation_url: params[:animation_url],
      image: params[:image],
      description: params[:description],
      is_primary_sale: params[:is_primary_sale],
      is_edition: params[:is_edition],
      creators: params[:creators],
    })

    if listing.errors.any?
      puts "Failed to save listing: #{listing.errors.full_messages.join(", ")}"
      return render json: { status: 'error', msg: "Failed to save token submission" }, status: :unprocessable_entity
    else
      curation.submitted_token_mints ||= []
      curation.submitted_token_mints << listing.mint
      curation.save

      return render json: { status: 'success', msg: 'Token submitted', listing: listing }
    end
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
      puts "ncuration ame: #{token.curation.name}"
      puts "token price: #{token.buy_now_price}"
      sent_count = ActionCable.server.broadcast("notifications_listings_#{token.curation.name}", {
        message: 'Listing Update', 
        data: { 
          mint: token.mint, 
          listed_status: token.listed_status,
          buy_now_price: token.buy_now_price,
          listing_receipt: token.listing_receipt
        }
      })
      puts "sent_count: #{sent_count}"
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