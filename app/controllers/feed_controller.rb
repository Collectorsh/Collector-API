# frozen_string_literal: true

class FeedController < ApplicationController
  def get
    feed = []
    ids = []
    user_id = params[:user_id]
    ids << user_id

    # The reverse Nightman
    children = User.where(parent_id: user_id).pluck(:id)
    (ids << children) && ids = ids.flatten if children

    feed << fetch_sales(ids, 20)
    # feed << fetch_watchlist_bids(user_id, 20) unless user_id
    feed << fetch_bids(ids, 20)
    feed << fetch_marketplace_sales(ids, 20)
    feed << fetch_marketplace_listings(ids, 20)

    feed = feed.flatten.sort { |a, b| b[:time] <=> a[:time] }

    render json: feed
  end

  def following
    return render json: { status: 'error', msg: 'API Key missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'API Key not found' } unless user

    following = user.user_followings.pluck(:following_id)

    feed = []

    feed << fetch_sales(nil, 100, following)
    feed << fetch_bids(nil, 100, following)
    feed << fetch_marketplace_sales(nil, 100, following)
    feed << fetch_marketplace_listings(nil, 100, following)

    feed = feed.flatten.sort { |a, b| b[:time] <=> a[:time] }

    render json: feed[0..49]
  end

  def listings
    feed = []

    MarketplaceListing.where("timestamp > '#{(Time.now - 7.days).to_i}'")
                      .order(timestamp: :desc).each do |listing|
      feed << { time: listing.timestamp, attributes: listing.attributes }
    end

    feed = feed.sort { |a, b| b[:time] <=> a[:time] }

    render json: feed[0..49]
  end

  private

  def fetch_marketplace_listings(user_id = nil, limit = 20, following = nil)
    results = []

    listings = MarketplaceListing.select("users.parent_id, users.username, users.id as user_id,
      users.twitter_profile_image, users.twitter_screen_name, marketplace_listings.timestamp as time,
      marketplace_listings.*").joins(:user).where("users.username IS NOT NULL")
    listings = listings.where(user_id: user_id) if user_id
    listings = listings.where(user_id: following) if following
    listings = listings.order(id: :desc).limit(limit)

    listings.each do |listing|
      listing = check_for_parent(listing)
      results << { type: 'listing', username: listing.username, user_id: listing.user_id,
                   twitter_profile_image: listing.twitter_profile_image,
                   twitter_screen_name: listing.twitter_screen_name,
                   time: listing.time, artist: listing.artist_name&.name, attributes: listing.attributes }
    end
    results
  end

  def fetch_marketplace_sales(user_id = nil, limit = 20, following = nil)
    results = []

    sales = MarketplaceSale.select("users.parent_id, users.username, users.id as user_id, users.twitter_profile_image,
      users.twitter_screen_name, marketplace_sales.timestamp as time, marketplace_sales.*")
                           .joins(:user).where("users.username IS NOT NULL")
    sales = sales.where.not(transaction_type: 'auction')
    sales = sales.where(user_id: user_id) if user_id
    sales = sales.where(user_id: following) if following
    sales = sales.order(id: :desc).limit(limit)

    sales.each do |sale|
      sale = check_for_parent(sale)

      results << { type: 'sale', username: sale.username, user_id: sale.user_id,
                   twitter_profile_image: sale.twitter_profile_image,
                   twitter_screen_name: sale.twitter_screen_name,
                   time: sale.time, artist: sale.artist_name&.name, attributes: sale.attributes }
    end
    results
  end

  def fetch_bids(user_id = nil, limit = 20, following = nil)
    results = []

    bids = Bid.select("users.parent_id, users.username, users.id as user_id, users.twitter_profile_image,
      users.twitter_screen_name, bids.created_at as time, bids.bid as amount, bids.*, auctions.*")
              .joins(:user, :auction).where("users.username IS NOT NULL")
    bids = bids.where(user_id: user_id) if user_id
    bids = bids.where(user_id: following) if following
    bids = bids.order(id: :desc).limit(limit)

    bids.each do |bid|
      bid = check_for_parent(bid)

      results << { type: 'bid', username: bid.username, user_id: bid.user_id,
                   twitter_profile_image: bid.twitter_profile_image,
                   twitter_screen_name: bid.twitter_screen_name,
                   time: bid.time.to_i, amount: bid.amount, artist: bid.auction.brand_name, attributes: bid.auction.attributes }
    end
    results
  end

  def fetch_sales(user_id = nil, limit = 20, following = nil)
    results = []

    sales = Sale.select("users.parent_id, users.twitter_profile_image, users.username, users.id as user_id")
                .select("users.twitter_screen_name as twitter_screen_name, sales.*")
                .joins(:user).where("users.username IS NOT NULL")
    sales = sales.where(user_id: user_id) if user_id
    sales = sales.where(user_id: following) if following
    sales = sales.order(id: :desc).limit(limit)

    sales.each do |sale|
      sale = check_for_parent(sale)

      results << { type: 'won', username: sale.username, user_id: sale.user_id,
                   twitter_profile_image: sale.twitter_profile_image,
                   twitter_screen_name: sale.twitter_screen_name,
                   time: sale.end_time, artist_name: sale.brand_name, attributes: sale.attributes }
    end
    results
  end

  # The Nightman hack
  def check_for_parent(obj)
    return obj unless obj.parent_id

    user = User.find_by_id(obj.parent_id)
    obj.username = user.username
    obj
  end

  # Deprecate this at some stage
  def fetch_watchlist_bids(user_id, limit = 20)
    results = []

    twitter_names = User.pluck(:twitter_screen_name).map { |e| "'#{e}'" }.join(', ')

    unless user_id
      bids = WatchlistBid.select("watchlists.name as username, watchlists.image as twitter_profile_image,
        watchlists.twitter_screen_name, watchlist_bids.created_at as time, watchlist_bids.bid as amount,
        watchlist_bids.*, auctions.*")
                         .joins(:watchlist, :auction)
                         .where("watchlists.twitter_screen_name NOT IN (#{twitter_names})")
                         .order(id: :desc)
                         .limit(limit)

      bids.each do |wl|
        results << { type: 'watchlist', username: wl.username, twitter_screen_name: wl.twitter_screen_name,
                     twitter_profile_image: wl.twitter_profile_image, time: wl.time.to_i, amount: wl.amount,
                     artist_name: wl.auction.brand_name, attributes: wl.auction.attributes }
      end
    end
    results
  end
end
