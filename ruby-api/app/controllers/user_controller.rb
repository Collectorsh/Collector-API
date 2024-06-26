# frozen_string_literal: true

class UserController < ApplicationController
  def getusername
    unless (user = User.where("public_keys LIKE '%#{params[:public_key]}%'").last)
      return render json: { status: 'error',
                            msg: 'Publickey not found' }
    end

    render json: { status: 'success', username: user.username, default_visibility: user.default_visibility,
                   public_keys: user.public_keys, gallery_view: user.gallery_view,
                   twitter_screen_name: user.twitter_screen_name, twitter_profile_image: user.twitter_profile_image }
  rescue StandardError => e
    Rails.logger.error("Error getting username: #{e.message}")
    render json: { status: 'error', msg: 'An unknown error has occurred' }
  end

  def from_api_key
    return render json: { status: 'error', msg: 'API Key missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'API Key not found' } unless user

    user = user.attributes

    following = get_following(user)
    user['following'] = following.to_a

    render json: { status: 'success', user: user }
  rescue StandardError => e
    Rails.logger.error("Error getting user from api key: #{e.message}")
    puts "error getting from api _key: #{e.message}"
    render json: { status: 'error', msg: 'An unknown error has occurred' }
  end

  def create_or_update_username
    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user
    return render json: { status: 'error', msg: 'Username is blank' } if params[:username].empty?

    if RestrictedUsername.find_by_name(params[:username])
      return render json: { status: 'error',
                            msg: 'Username is taken' }
    end

    user.username = params[:username].strip
    user.save

    return render json: { status: 'success', user: user } if user.valid?

    render json: { status: 'error', msg: user.errors.full_messages.join(', ') }
  rescue StandardError => e
    Rails.logger.error("Error creating or updating username: #{e.message}")
    render json: { status: 'error', msg: 'An unknown error has occurred' }
  end

  def default_visibility
    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user

    user.update_attribute(:default_visibility, params[:visibility])
    render json: { status: 'success', user: user }
  end

  def gallery_view
    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user

    user.update_attribute(:gallery_view, params[:layout])
    render json: { status: 'success', user: user }
  end

  def getpublickeys_fromusername
    unless (user = User.find_by("LOWER(username)= ?", params[:username].downcase))
      return render json: { status: 'error',
                            msg: 'Username not found' }
    end

    render json: { status: 'success', public_keys: user.public_keys, gallery_view: user.gallery_view }
  rescue StandardError => e
    Rails.logger.error e.backtrace
    render json: { status: 'error', msg: 'An unknown error has occurred' }
  end

  def from_username
    user = User.find_by("LOWER(username)= ?", params[:username].downcase)

    if !user
      user = User.find_by("public_keys LIKE '%#{params[:username]}%'")
    end

    return render json: { status: 'error', msg: 'Username not found' } unless user

    render json: { status: 'success', user: user.public_info }
  rescue StandardError => e
    Rails.logger.error e.backtrace
    render json: { status: 'error', msg: 'An unknown error has occurred' }
  end

  def getpublickeys
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    render json: { status: 'success', public_keys: user.public_keys }
  rescue StandardError => e
    Rails.logger.error e.backtrace
    render json: { status: 'error', msg: 'An unknown error has occurred' }
  end

  def delete_wallet
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    keys = user.public_keys
    keys.delete params[:public_key]
    user.public_keys = keys
    user.save!

    render json: { status: 'success', user: user }
  rescue StandardError => e
    Rails.logger.error e.backtrace
    render json: { status: 'error', msg: 'An unknown error has occurred' }
  end

  def request_nonce
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    render json: { status: 'success', nonce: user.nonce }
  end

  def add_wallet
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    return render json: { status: 'error', msg: 'Signature verifcation failed' } unless verify_signature(
      params[:public_key], user.nonce
    )

    # existing_user = User.where("public_keys LIKE '%#{params[:public_key]}%' AND id <> #{user.id}").first
    existing_user = User.where("public_keys LIKE ? AND id <> ?", "%#{params[:public_key]}%", user.id).first



    if existing_user
      #check if they have any associated listings or curations
      existing_names = ArtistName.exists?(artist_id: existing_user.id)
      existing_listings = CurationListing.exists?(["artist_id = ? OR owner_id = ?", existing_user.id, existing_user.id])
      existing_curations = Curation.exists?(curator_id: existing_user.id)
      existing_indexed_mints = MintedIndexer.exists?(["artist_id = ? OR owner_id = ?", existing_user.id, existing_user.id])
      existing_sales_history = SalesHistory.exists?(["buyer_id = ? OR seller_id = ? OR artist_id = ?", existing_user.id, existing_user.id, existing_user.id])
      existing_waitlist_signup = WaitlistSignup.exists?(user_id: existing_user.id)

      #if unable to delete, then return all assoaciated addresses and tell the user to open that account and remove the address
      if existing_names || existing_listings || existing_curations || existing_indexed_mints || existing_sales_history || existing_waitlist_signup
        return render json: { status: 'error', msg: 'Address already in use', existing_user: existing_user }
      end

      #if not, then delete the user and continue adding
      begin
        unless existing_user.destroy
          return render json: { status: 'error', msg: 'Unable to delete old account', existing_user: existing_user }
        end

        puts "user destroyed"
      rescue => e
        # Log the error and return a response indicating failure
        Rails.logger.error "Failed to delete user: #{e.message}"
        return render json: { status: 'error', msg: 'An error occurred while trying to delete old account', existing_user: existing_user }
      end

    end

    keys = user.public_keys
    unless keys.include? params[:public_key]
      user.public_keys = keys.push(params[:public_key])
      user.save!
    end

    render json: { status: 'success', user: user }
  rescue StandardError => e
    Rails.logger.error "Error adding wallet: #{e.message}"
    render json: { status: 'error', msg: 'An unknown error has occurred' }
  end

  def add_wallet_with_secret
    unless params[:secret] == '1fc958df4a8c1e6ce327bae211acae44'
      return render json: { status: 'error',
                            msg: 'Invalid API secret' }
    end

    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    # existing_user = User.where("public_keys LIKE '%#{params[:public_key]}%' AND id <> #{user.id}").first
    existing_user = User.where("public_keys LIKE ? AND id <> ?", "%#{params[:public_key]}%", user.id).first

    if existing_user
      #check if they have any associated listings or curations
      existing_names = ArtistName.exists?(artist_id: existing_user.id)
      existing_listings = CurationListing.exists?(["artist_id = ? OR owner_id = ?", existing_user.id, existing_user.id])
      existing_curations = Curation.exists?(curator_id: existing_user.id)
      existing_indexed_mints = MintedIndexer.exists?(["artist_id = ? OR owner_id = ?", existing_user.id, existing_user.id])
      existing_sales_history = SalesHistory.exists?(["buyer_id = ? OR seller_id = ? OR artist_id = ?", existing_user.id, existing_user.id, existing_user.id])
      existing_waitlist_signup = WaitlistSignup.exists?(user_id: existing_user.id)

      #if unable to delete, then return all assoaciated addresses and tell the user to open that account and remove the address
      if existing_names || existing_listings || existing_curations || existing_indexed_mints || existing_sales_history || existing_waitlist_signup
        return render json: { status: 'error', msg: 'Address already in use', existing_user: existing_user }
      end

      #if not, then delete the user and continue adding
      begin
        unless existing_user.destroy
          return render json: { status: 'error', msg: 'Unable to delete old account', existing_user: existing_user }
        end

        puts "user destroyed"
      rescue => e
        # Log the error and return a response indicating failure
        Rails.logger.error "Failed to delete user: #{e.message}"
        return render json: { status: 'error', msg: 'An error occurred while trying to delete old account', existing_user: existing_user }
      end

    end

    keys = user.public_keys
    unless keys.include? params[:public_key]
      user.public_keys = keys.push(params[:public_key])
      user.save!
    end

    render json: { status: 'success', user: user }
  rescue StandardError => e
    Rails.logger.error "Error adding wallet: #{e.message}"
    render json: { status: 'error', msg: 'An unknown error has occurred' }
  end

  def merge_accounts
    primary_user = User.find_by_api_key(params[:api_key])
    merging_user = User.find_by_api_key(params[:merging_api_key])
    return render json: { status: 'error', msg: 'Api keys not valid' } unless primary_user.present? && merging_user.present?

    success = false;

    ActiveRecord::Base.transaction do
      # Merge the accounts

      #artist_names
      ArtistName.where(artist_id: merging_user.id).update_all(artist_id: primary_user.id)
      
      #curation_listings
      CurationListing.where(artist_id: merging_user.id).update_all(artist_id: primary_user.id)
      CurationListing.where(owner_id: merging_user.id).update_all(owner_id: primary_user.id)
     
      #curations
      Curation.where(curator_id: merging_user.id).update_all(curator_id: primary_user.id)

      #minted_indexer
      MintedIndexer.where(artist_id: merging_user.id).update_all(artist_id: primary_user.id)
      MintedIndexer.where(owner_id: merging_user.id).update_all(owner_id: primary_user.id)

      #sales_history
      SalesHistory.where(buyer_id: merging_user.id).update_all(buyer_id: primary_user.id)
      SalesHistory.where(seller_id: merging_user.id).update_all(seller_id: primary_user.id)
      SalesHistory.where(artist_id: merging_user.id).update_all(artist_id: primary_user.id)

      #waitlist_signup
      WaitlistSignup.where(user_id: merging_user.id).update_all(user_id: primary_user.id)

      primary_keys = primary_user.public_keys || []
      merging_keys = merging_user.public_keys || []

      # Combine the keys from both users, ensuring uniqueness
      combined_keys = (primary_keys + merging_keys).uniq
      primary_user.public_keys = combined_keys
      primary_user.save!

      merging_user.destroy!

      # if destroy is successful, then set success to true
      success = true
    end

    if success
      render json: { status: 'success', user: primary_user}
    else
      render json: { status: 'error', msg: 'Unable to merge accounts' }
    end
  rescue StandardError => e
    Rails.logger.error "Error merging accounts: #{e.message}"
    render json: { status: 'error', msg: 'An unknown error has occurred' }
  end

  def save
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    if params[:attributes][:username]
      return render json: { status: 'error', msg: 'Username is blank' } if params[:attributes][:username].empty?

      if RestrictedUsername.find_by_name(params[:attributes][:username].downcase)
        return render json: { status: 'error',
                              msg: 'Username is taken' }
      end
    end

    user.update(params[:attributes].permit(:username, :default_visibility, :border, :shadow, :rounded, :description,
                                           :names, :estimated_value, :notify_trending, :notify_outbid,
                                           :show_artist_name, :watchlist_to_dm, :notify_new_artist,
                                           :notify_twitter, :notify_email, :email, :profile_image, :name, :bio, :artist, :public_key))
    return render json: { status: 'error', msg: user.errors.full_messages } unless user.errors.empty?

    render json: { status: 'success', user: user }
  end

  def bids
    unless (user = User.find_by_id(params[:user_id]))
      render json: { status: 'error',
                     msg: 'User not found' }
    end

    results = []

    user_bids = user.bids.where("bids.end_time > #{Time.now.to_i}")
    User.where(parent_id: user.id).each do |u|
      user_bids += u.bids.where("bids.end_time > #{Time.now.to_i}")
    end

    user_bids.each do |bid|
      auction = bid.auction
      results << bid.attributes.merge({ highest_bid: auction.highest_bid, image: auction.image, name: auction.name,
                                        brand_name: auction.brand_name, mint: auction.mint, source: auction.source,
                                        highest_bidder_username: auction.highest_bidder_username,
                                        number_bids: auction.number_bids })
    end

    render json: { status: 'success', bids: results }
  end

  def follow_unfollow
    return render json: { status: 'error', msg: 'API Key missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'API Key not found' } unless user

    user = user.attributes

    if params[:doaction] == 'follow'
      UserFollowing.where(user_id: user['id'],
                          following_id: params[:user_id]).first_or_create
    end

    if params[:doaction] == 'unfollow'
      UserFollowing.where(user_id: user['id'],
                          following_id: params[:user_id]).destroy_all
    end

    following = get_following(user)
    user['following'] = following.to_a

    render json: { status: 'success', user: user }
  end

  def follows
    user = User.find_by_id(params[:user_id])
    return render json: { status: 'error', msg: 'User not found' } unless user

    following = user.user_followings.collect do |f|
      User.find_by_id(f.following_id)&.attributes&.except('api_key', 'nonce', 'twitter_oauth_secret',
                                                          'twitter_oauth_token')
    end

    followers = UserFollowing.where(following_id: user.id)
    followers = followers.collect do |f|
      User.find_by_id(f.user_id)&.attributes&.except('api_key', 'nonce', 'twitter_oauth_secret', 'twitter_oauth_token')
    end

    render json: { status: 'success', following: following, followers: followers }
  end

  def save_mints
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    params[:mints].each do |m|
      user.mints.where(name: m['name'], description: m['description'], image: m['image'], uri: m['uri'], symbol: m['symbol'], mint: m['mint'], address: m['address'],
                       collection: m['collection'], edition_type: m['edition_type'], supply: m['supply'], max_supply: m['max_supply'], print: m['print']).first_or_create
    end

    render json: { status: 'success', user: user }
  end

  def mints
    unless (user = User.where(id: params[:id]).last)
      return render json: { status: 'error',
                            msg: 'User not found' }
    end

    collections = []
    user.mints.where("collection IS NOT NULL").pluck(:collection).uniq.each do |cm|
      m = Mint.find_by_mint(cm)
      next unless m

      collections << { name: m.name, description: m.description, address: cm }
    end

    listings = MarketplaceListing.where(listed: true, mint: user.mints.pluck(:mint)).count

    render json: { status: 'success', mints: user.mints, collections: collections, listings: listings }
  end

  def update_bio
    return render json: { status: 'error', msg: 'Auth missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user

    user.update_attribute(:bio_delta, params[:bio_delta])
    render json: { status: 'success', user: user }
  end
  def update_profile_image
    return render json: { status: 'error', msg: 'Auth missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user

    user.update_attribute(:profile_image, params[:profile_image])
    render json: { status: 'success', user: user }
  end
  def update_banner_image
    return render json: { status: 'error', msg: 'Auth missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user

    user.update_attribute(:banner_image, params[:banner_image])
    render json: { status: 'success', user: user }
  end
  def update_socials
    return render json: { status: 'error', msg: 'Auth missing' } unless params[:api_key]
    
    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user

    user.update_attribute(:socials, params[:socials])
    render json: { status: 'success', user: user }
  end
  def update_display_name
    return render json: { status: 'error', msg: 'Auth missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user

    user.update_attribute(:name, params[:name])
    render json: { status: 'success', user: user }
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end
  def get_curator_by_username
    unless (user = User.find_by("LOWER(username)= ?", params[:username].downcase))
      return render json: { status: 'error', msg: 'Username not found' }
    end

    # unless user.subscription_level == 'pro'
    #   return render json: { status: 'error', msg: 'User is not a curator' }
    # end

    user_hash = user.public_info
    user_hash['curations'] = user.curations.where(hidden: false).map(&:condensed_with_curator_and_listings)

    render json: { status: 'success', curator: user_hash }
  rescue StandardError => e
    puts "error: #{e.message}"
    render json: { status: 'error', msg: 'An unknown error has occurred' }
  end

  def get_user_by_address
    return render json: { status: 'error', msg: 'Address missing' } unless params[:address]

    user = User.find_by("public_keys LIKE '%#{params[:address]}%'")
    return render json: { status: 'error', msg: 'User not found' } unless user

    render json: { status: 'success', user: user.public_info}
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def save_curations_order
    return render json: { status: 'error', msg: 'params missing' } unless params[:curation_ids]
    
    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user

    user.update_attribute(:curations_order, params[:curation_ids])

    render json: { status: 'success', user: user }
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end
  private

  def verify_signature(public_key, nonce)
    verify_key = RbNaCl::VerifyKey.new(decode_base58(public_key))
    signature = params[:signature]['data'].pack('c*')
    message = "#{Rails.configuration.sign_message}#{nonce}"
    Rails.logger.debug message
    verify_key.verify(signature, message)
  rescue RbNaCl::BadSignatureError
    false
  end

  def decode_base58(str)
    Btc::Base58.data_from_base58 str
  end

  def get_following(user)
    user_following = UserFollowing.where(user_id: user['id']).pluck(:following_id)
    User.select(:id, :username, :twitter_profile_image).where(id: user_following)
  end

  def verify
    return render json: { status: 'error', msg: 'API Key missing' } unless params[:api_key]
    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user

    return render json: {status: 'success', verified: true}
  end
 
end
