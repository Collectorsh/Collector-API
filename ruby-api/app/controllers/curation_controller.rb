class CurationController < ApplicationController
  before_action :get_authorized_curation, only: [:generate_viewer_passcode, :update_name, :update_approved_artists, :save_draft_content, :unpublish_content, :publish_content, :get_private_content, :hide_curation]
  before_action :get_viewer_authorized_curation, only: [:get_viewer_private_content, :update_self_as_approved_artists]

  # defaults to type "curator"
  def create
    return render json: { status: 'error', msg: 'Auth missing' } unless params[:api_key]
    
    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user 
    # return render json: { status: 'error', msg: 'Only approved curators can create a Curation' } unless user.subscription_level === "pro"
    puts "Creating curator curation: #{params[:name]}"

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
    Rails.logger.error("Failed to create curation: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  # type is "artist" || "collector"
  def create_personal
    return render json: { status: 'error', msg: 'Auth missing' } unless params[:api_key]
    
    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user 
    # return render json: { status: 'error', msg: 'Only approved curators can create a Curation' } unless user.subscription_level === "pro"
    return render json: { status: 'error', msg: 'Proper curation type not sent' } unless params[:curation_type].present? && ["artist", "collector"].include?(params[:curation_type])
    puts "Creating personal curation: #{params[:name]}"

    # round fee to second decimal place
    curator_fee = params[:curator_fee].to_f.round(2) 

    curation = Curation.create(
      name: params[:name],
      curator_id: user.id,
      auction_house_address: params[:auction_house_address],
      curation_type: params[:curation_type],
      curator_fee: 0
    )

    if curation.errors.any?
      puts "Failed to save curation: #{curation.errors.full_messages.join(", ")}"
      Rails.logger.error("Failed to save curation: #{curation.errors.full_messages.join(", ")}")
      return render json: { status: 'error', msg: "Failed to save Curation" }, status: :unprocessable_entity
    else
      return render json: { status: 'success', msg: 'Curation created' }
    end
  rescue StandardError => e
    puts "Failed to create curation: #{e.message}"
    Rails.logger.error("Failed to create curation: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_by_name

    curation = nil;

    if params[:username].present?
      curation = Curation.joins(:curator).find_by(
        "LOWER(curations.name) = ? AND curations.hidden = ? AND LOWER(users.username) = ?", 
        params[:name].downcase, false, params[:username].downcase
      )
    else 
      curation = Curation.find_by("LOWER(name) = ? AND hidden = ?", params[:name].downcase, false)
    end

    if curation.nil?
      return render json: { error: "Curation not found" }, status: :not_found
    end
    
    curation_hash = curation.public_info
    
    curation_hash["curator"] = curation.curator.public_info

    render json: curation_hash
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def search_by_name
    unless curations = Curation.where("LOWER(name) LIKE ? AND hidden = ?", "%#{params[:name].downcase}%", false)
      return render json: { error: "Curation not found" }, status: :not_found
    end

    curations_hash = curations.map do |curation|
      curation_hash = curation.public_info
      curation_hash["curator"] = curation.curator.public_info
      curation_hash
    end
    
    render json: curations_hash
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def search_published

    search = params[:search].downcase

    curations = Curation.joins("INNER JOIN users ON users.id = curations.curator_id").where(
    "(LOWER(curations.name) LIKE :search OR LOWER(users.name) LIKE :search OR LOWER(users.username) LIKE :search) AND curations.hidden = :hidden AND curations.is_published = :published", 
    search: "%#{search}%", 
    hidden: false, 
    published: true
  )
    
    if curations.empty?
      return render json: { error: "Curation not found" }, status: :not_found
    end

    curations_hash = curations.map(&:condensed_with_curator)
    
    render json: {curation_results: curations_hash}
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_all_published
    
    # Pagination
    page = params[:page].to_i || 1
    per_page = params[:per_page].to_i || 12
    offset = (page - 1) * per_page
    
    custom_curation_query = nil

    order_by = "first_published_at DESC" #recent

    if params[:order_by] == "a-z"
      order_by = "name ASC"
    elsif params[:order_by] == "z-a"
      order_by = "name DESC"
    elsif params[:order_by] == "oldest"
      order_by = "first_published_at ASC"
    elsif params[:order_by] == "most-sales"
      custom_curation_query_ids = Curation.select("curations.id, curations.name, COALESCE(SUM(sales_history.price), 0) AS total_sales")
                                      .joins("LEFT JOIN sales_history ON sales_history.curation_id = curations.id")
                                      .where(hidden: false, is_published: true)
                                      .group("curations.id")
                                       .order(Arel.sql('COALESCE(SUM(sales_history.price), 0) DESC'))
                                      .limit(per_page)
                                      .offset(offset)
                                      .pluck(:id)  # Fetches only the IDs

      custom_curations = Curation.where(id: custom_curation_query_ids)

      custom_curation_query = custom_curation_query_ids.map{|id| custom_curations.find{|c| c.id == id}}

    # elsif params[:order_by] == "popular"
    #   # Set up the query parameters
    #   url = "https://plausible.io/api/v1/stats/breakdown"

    #   query_params = {
    #     site_id: 'collector.sh',
    #     period: '30d',
    #     property: 'event:page',
    #     limit: 10,
    #     filters: 'event:page==/*/*'
    #   }

    #   # Include the Authorization header with the Bearer token
    #   headers = {
    #     "Authorization" => "Bearer #{ENV['PLAUSIBLE_API_KEY']}",
    #     "Content-Type" => "application/json"
    #   }

    #   # Perform the GET request with HTTParty
    #   plausible_results = HTTParty.get(url, query: query_params, headers: headers)

    #   if plausible_results.code == 200

    #     parse_results = []

    #     plausible_results.parsed_response["results"].each do |result|
    #       page_path = result["page"] # Assuming 'page' is the key where the path is stored
    #       parts = page_path.split('/').reject(&:empty?) # Split by '/', and remove empty strings if any
    #       if parts.size >= 2 && parts[0] != "art" && parts[0] != "curations"
    #         # Output the second part of the page path
    #         parse_results << parts[1]
    #       end
    #     end

    #     paginated_results = parse_results[offset, per_page]  # This will fetch the slice of results for the current page

    #     puts "Paginated results: #{paginated_results}"

    #     custom_curations = Curation.where(hidden: false, is_published: true, name: paginated_results)

    #     custom_curation_query = paginated_results.map{|name| custom_curations.find{|c| c.name == name}}
    #     custom_curation_query = custom_curation_query.compact

    #   end
    end


    curations = nil
    
    if (custom_curation_query.present?) 
      curations = custom_curation_query;
    else 
      curations = Curation.where(hidden: false, is_published: true).order(order_by).offset(offset).limit(per_page)
    end

    curation_total = Curation.where(hidden: false, is_published: true).count

    if curations.empty?
      return render json: { error: "Curation not found" }, status: :not_found
    end

    curations_hash = curations.map(&:condensed_with_curator)
    
    render json: {curation_results: curations_hash, total: curation_total}
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_listings_and_artists_by_name
    # unless curation = Curation.find_by("LOWER(name) = ?", params[:name].downcase)
    #   return render json: { error: "Curation not found" }, status: :not_found
    # end

    unless curation = Curation.joins(:curator).find_by(
        "LOWER(curations.name) = ? AND LOWER(users.username) = ?", 
        params[:name].downcase, params[:username].downcase
      )
      return render json: { error: "Curation not found" }, status: :not_found
    end
        
    #filter to exclude nft_state = "burned"
    listings = curation.curation_listings.map(&:attributes).select{|x| x["nft_state"] != "burned"}

    artists = (User.where(id: listings.map {|l| l["artist_id"]}).map(&:public_info) + curation.approved_artists).uniq

    owners = User.where(id: listings.map {|l| l["owner_id"]}).map(&:public_info).uniq

    render json: {
      submitted_token_listings: listings,
      approved_artists: artists,
      owners: owners
    }

  rescue StandardError => e
    Rails.logger.error("Failed to get listings and artists by name: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_by_approved_artist
    return render json: { status: 'error', msg: 'Artist id not sent' } unless params[:artist_id].present?
    artist_id = params[:artist_id].to_i

    # //by submitted listing
    curation_ids_subquery = CurationListing.where(artist_id: artist_id).select(:curation_id)
    # Condition to check for artist_id in approved_artist_ids array
    approved_artist_condition = Curation.arel_table[:approved_artist_ids].contains([artist_id])

    curations = Curation.where(id: curation_ids_subquery)
                    .or(Curation.where(approved_artist_condition))
                    .order('created_at DESC')
                    .map(&:condensed_with_curator_and_listings_and_passcode)


    render json: curations
  rescue StandardError => e
    Rails.logger.error("Failed to get curations by approved artist: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_by_listing_mint
    return render json: { status: 'error', msg: 'Mint not sent' } unless params[:mint].present?
    curations = CurationListing.includes(:curation)
                  .where(mint: params[:mint])
                  .map { |listing| listing.curation.condensed_with_curator_and_listings }

    render json: {status: 'success', curations: curations}
  rescue StandardError => e
    Rails.logger.error("Failed to get curations by listing mint: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_highlighted_curations
    highlight = CurationHighlight.find_by(name: params[:highlight_group] || "homepage")
    curations = highlight.fetch_curations
    render json: curations
  rescue StandardError => e
    Rails.logger.error("Failed to get highlighted curations: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def set_highlighted_curations
    user = User.find_by_api_key(params[:api_key])
    adminIDs = [
      720, #Nate (username: n8solomon)
      5421, #Scott (username: EV3)
    ]
    authorized = user && adminIDs.include?(user.id)

    return render json: { status: 'error', msg: 'Not authorized' } unless authorized

    highlight = CurationHighlight.find_by(name: params[:highlight_group] || "homepage")
    highlight.curation_ids = params[:curation_ids]
    highlight.save

    render json: { status: 'success', msg: 'Highlighted curations set' }
  rescue StandardError => e
    Rails.logger.error("Failed to set highlighted curations: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_latest_curations
    distinct_curations_sql = Curation
                          .select("DISTINCT ON (curator_id) id, first_published_at")
                          .where(is_published: true)
                          .where.not("published_content ->> 'banner_image' IS NULL")
                          .order(:curator_id, first_published_at: :desc)
                          .to_sql


    # First, turn the SQL back into an ActiveRecord relation
    distinct_curations = Curation.from("(#{distinct_curations_sql}) as distinct_curations")

    # Then, perform a join and order by first_published_at DESC
    curations = Curation.includes(:curator)
                        .joins("INNER JOIN (#{distinct_curations_sql}) as recent_curations ON curations.id = recent_curations.id")
                        .order('recent_curations.first_published_at DESC')
                        .limit(9)



    curations_with_curators = curations.map(&:condensed_with_curator)

    render json: curations_with_curators
  rescue StandardError => e
    Rails.logger.error("Failed to get latest curations: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_private_content
    curation = @authorized_curation

    init_content = {
      modules: []
    }

    render json: { 
      draft_content: curation.draft_content || init_content,
      private_key_hash: curation.private_key_hash,
      viewer_passcode: curation.viewer_passcode
    }
  rescue StandardError => e
    Rails.logger.error("Failed to get private content: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_viewer_private_content
    curation = @viewer_authorized_curation

    init_content = {
      modules: []
    }

    render json: { 
      draft_content: curation.draft_content || init_content,
    }
  rescue StandardError => e
    Rails.logger.error("Failed to get viewer private content: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def publish_content
    curation = @authorized_curation
    
    content = params[:draft_content] || curation.draft_content

    curation.published_content = content
    curation.is_published = true
    if curation.first_published_at.nil?
      curation.first_published_at = Time.current
    end
    curation.save

    render json: { status: 'success', msg: 'Curation published' }
  rescue StandardError => e
    Rails.logger.error("Failed to publish content: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def unpublish_content
    curation = @authorized_curation

    curation.is_published = false
    curation.save

    render json: { status: 'success', msg: 'Curation unpublished' }
  rescue StandardError => e
    Rails.logger.error("Failed to unpublish content: #{e.message}")
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
    Rails.logger.error("Failed to save draft content: #{e.message}")
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
    Rails.logger.error("Failed to update approved artists: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def update_self_as_approved_artists
    curation = @viewer_authorized_curation

    user = User.find_by_api_key(params[:api_key])

    if curation.approved_artist_ids.include?(user.id)
      return render json: { status: 'success', msg: 'User already approved' }
    end

    if user.update(curator_approved: true)
      # Add the user's ID to the approved_artist_ids array if not already there
      curation.approved_artist_ids << user.id
      unless curation.save
        return render json: { status: 'error', msg: curation.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    else
      return render json: { status: 'error', msg: user.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end

    render json: { status: 'success', curation: curation.condensed_with_curator_and_listings_and_passcode }
  rescue StandardError => e
    Rails.logger.error("Failed to update self as approved artist: #{e.message}")
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
    Rails.logger.error("Failed to update name: #{e.message}")
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def check_name_availability
    new_name = params[:new_name]&.strip

    return render json: { status: 'error', msg: 'Identity not sent' } unless new_name.present? && params[:curator_id].present?

    if Curation.find_by("LOWER(name) = ? AND curator_id = ?", new_name.downcase, params[:curator_id])
      render json: { status: 'error', msg: 'Name taken' }
    else
      render json: { status: 'success', msg: 'Name available' }
    end
  end

  def generate_viewer_passcode
    curation = @authorized_curation
    passcode = SecureRandom.hex(6)

    puts "Generated passcode: #{passcode}"

    if curation.update(viewer_passcode: passcode)
      return render json: { status: 'success', passcode: passcode }
    else
      return render json: { status: 'error', msg: curation.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error("Failed to generate viewer passcode: #{e.message}")
    render json: { status: 'error', msg: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_all_curator_curations_with_private_hash
    user = User.find_by_api_key(params[:api_key])
    adminIDs = [
      720, #Nate (username: n8solomon)
      5421, #Scott (username: EV3)
    ]
    authorized = user && adminIDs.include?(user.id)

    return render json: { status: 'error', msg: 'Not authorized' } unless authorized

    curations = Curation.includes(:curator).where(curation_type: "curator").order(:name)

    curations = curations.map do |curation|
      # Creating a new hash that combines the curation's attributes, excluding some, and adding the curator's public info
      curation.attributes
              .except('draft_content', 'published_content')
              .merge(curator: curation.curator.public_info)
    end

    render json: curations
  rescue StandardError => e
    Rails.logger.error("Failed to get all curator curations with private hash: #{e.message}")
    render json: { status: 'error', msg: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def hide_curation
    curation = @authorized_curation
    if curation.update(hidden: true, name: "#{curation.name}-hidden-#{SecureRandom.hex(4)}")
      render json: { status: 'success', msg: 'Curation hidden' }
    else 
      render json: { status: 'error', msg: curation.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error("Failed to hide curation: #{e.message}")
    render json: { status: 'error', msg: "An error occurred: #{e.message}" }, status: :internal_server_error
  end
  
  private 

  def get_authorized_curation
    # unless curation = Curation.find_by("LOWER(name) = ?", params[:name].downcase)
    unless curation = Curation.find_by(id: params[:curation_id])
      return render json: { error: "Curation not found" }, status: :not_found
    end

    user = User.find_by_api_key(params[:api_key])
    authorized = user && user.id == curation.curator_id
    
    return render json: { status: 'error', msg: 'Not authorized' } unless authorized

    @authorized_curation = curation
  end

  def get_viewer_authorized_curation
    unless user = User.find_by_api_key(params[:api_key])
      return render json: { status: 'error', msg: 'Not authorized' }
    end 

    unless curation = Curation.find_by_viewer_passcode(params[:viewer_passcode])
      return render json: { error: "Curation not found" }, status: :not_found
    end

    @viewer_authorized_curation = curation
  end

end