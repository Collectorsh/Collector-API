class CurationController < ApplicationController
  before_action :get_authorized_curation, except: [:check_name_availability, :create, :get_by_name, :get_by_approved_artist, :get_highlighted_curations, :get_by_listing_mint]

  def create
    return render json: { status: 'error', msg: 'Auth missing' } unless params[:api_key]
    
    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user 
    return render json: { status: 'error', msg: 'Only approved curators can create a Curation' } unless user.subscription_level === "pro"
    puts "Creating curation: #{params[:name]}"

    # round fee to second decimal place
    curator_fee = params[:curator_fee].to_f.round(2) 

    curation = Curation.create(
      name: params[:name],
      curator_id: user.id,
      curator_fee: curator_fee,
      auction_house_address: params[:auction_house_address],
      private_key_hash: params[:private_key_hash],
      payout_address: params[:payout_address]
    )

    if curation.errors.any?
      puts "Failed to save curation: #{listing.errors.full_messages.join(", ")}"
      return render json: { status: 'error', msg: "Failed to save Curation" }, status: :unprocessable_entity
    else
      return render json: { status: 'success', msg: 'Curation created' }
    end
  rescue StandardError => e
    puts "Failed to create curation: #{e.message}"
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_by_name
    unless curation = Curation.find_by("LOWER(name) = ?", params[:name].downcase)
      return render json: { error: "Curation not found" }, status: :not_found
    end
    
    curation_hash = curation.public_info
    
    curation_hash["curator"] = curation.curator.public_info
    curation_hash["approved_artists"] = curation.approved_artists
    curation_hash["submitted_token_listings"] = curation.curation_listings

    render json: curation_hash
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_by_approved_artist
    return render json: { status: 'error', msg: 'Artist id not sent' } unless params[:artist_id].present?

    artist_id = params[:artist_id].to_i
    curations = Curation.where("approved_artist_ids @> ARRAY[?::integer]", artist_id)
      .order('created_at DESC')
      .map(&:condensed_with_curator)

    render json: curations
  end

  def get_by_listing_mint
    return render json: { status: 'error', msg: 'Mint not sent' } unless params[:mint].present?

    curations = CurationListing.where(mint: params[:mint]).map(&:curation).map(&:condensed_with_curator)

    render json: {status: 'success', curations: curations}
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_highlighted_curations
    highlighted = ENV['HIGHLIGHTED_CURATIONS'].split(',')
    curations = Curation.where(name: highlighted).map(&:condensed_with_curator)

    render json: curations
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_private_content
    curation = @authorized_curation

    init_content = {
      modules: []
    }

    render json: { 
      draft_content: curation.draft_content || init_content,
      private_key_hash: curation.private_key_hash
    }
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def publish_content
    curation = @authorized_curation
    
    content = params[:draft_content] || curation.draft_content

    curation.published_content = content
    curation.is_published = true
    curation.save

    render json: { status: 'success', msg: 'Curation published' }
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def unpublish_content
    curation = @authorized_curation

    curation.is_published = false
    curation.save

    render json: { status: 'success', msg: 'Curation unpublished' }
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def save_draft_content
    return render json: { status: 'error', msg: 'Draft not sent' } unless params[:draft_content]
    content = params[:draft_content]
    
    curation = @authorized_curation
    
    curation.draft_content = content
    curation.save

    render json: { status: 'success', msg: 'Curation draft saved' }
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def update_approved_artists
    return render json: { status: 'error', msg: 'Artists not sent' } unless params[:artist_ids]
    artist_ids = params[:artist_ids]
    curation = @authorized_curation

    confirmed_artist_ids = User.where(id: artist_ids).pluck(:id)
    User.where(id: confirmed_artist_ids).update_all(curator_approved: true)

    puts "Confirmed artist ids: #{confirmed_artist_ids}"

    if curation.update(approved_artist_ids: confirmed_artist_ids)
      render json: { status: 'success', msg: 'Artists Approved' }
    else
      render json: { status: 'error', msg: curation.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def update_name
    new_name = params[:new_name]&.strip

    return render json: { status: 'error', msg: 'New name not sent' } unless new_name.present?

    curation = @authorized_curation

    if curation.update(name: new_name)
      render json: { status: 'success', msg: 'Name Updated' }
    else
      render json: { status: 'error', msg: curation.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def check_name_availability
    new_name = params[:new_name]&.strip

    return render json: { status: 'error', msg: 'New name not sent' } unless new_name.present?

    if Curation.find_by("LOWER(name) = ?", new_name.downcase)
      render json: { status: 'error', msg: 'Name taken' }
    else
      render json: { status: 'success', msg: 'Name available' }
    end
  end

  private 

  def get_authorized_curation
    unless curation = Curation.find_by("LOWER(name) = ?", params[:name].downcase)
      return render json: { error: "Curation not found" }, status: :not_found
    end

    return render json: { status: 'error', msg: 'Auth missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    authorized = user && user.id == curation.curator_id

    return render json: { status: 'error', msg: 'Api key not valid' } unless authorized

    @authorized_curation = curation
  end
end