# frozen_string_literal: true

class FollowingController < ApplicationController
  def from_id
    unless (user = User.find_by(id: params[:user_id]))
      return render json: { status: 'error',
                            msg: 'User not found' }
    end

    following = []

    user.followings.each do |f|
      artist = f.artist_name

      following << { artist: artist.name, name: artist.name, twitter_profile_image: artist.twitter_profile_image,
                     twitter: artist.twitter }
    end

    render json: { status: 'success', following: following }
  end

  def get
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    render json: { status: 'success', following: user_following(user) }
  end

  def update
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    artist = ArtistName.find_by(name: params[:artist])

    follow = Following.where(user_id: user.id, artist_name_id: artist.id).first

    follow.update_attribute params[:notification_type].to_sym, params[:state]

    render json: { status: 'success', following: user_following(user) }
  end

  def search
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    following = user.artist_names.pluck(:name)

    artists = ArtistName.select(:name, :twitter).where("name ILIKE '%#{params[:artist]}%'")
                        .where.not(name: following).group(:name, :twitter)

    render json: { status: 'success', results: artists }
  end

  def auctions
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    return render json: { status: 'success', auctions: [] } if user.followings.empty?

    following = user.artist_names.pluck(:id)

    auctions = Auction.where(artist_name_id: following)
                      .where("end_time > #{Time.now.to_i} AND start_time < #{Time.now.to_i}")
                      .where("mint IS NOT NULL AND image IS NOT NULL")

    render json: { status: 'success', auctions: auctions }
  end

  def listings
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    return render json: { status: 'success', listings: [] } if user.followings.empty?

    following = user.artist_names.pluck(:id)

    results = MarketplaceListing.joins(:artist_name)
                                .where('marketplace_listings.artist_name_id': following)
                                .where("listed = true")
                                .where("mint IS NOT NULL AND image IS NOT NULL AND amount IS NOT NULL")

    listings = []

    results.each do |r|
      listing = listings.select { |l| l.name == r.name && l.artist_name == r.artist_name }.first
      listings << r && next unless listing

      if r.amount < listing.amount
        listings.delete_if { |l| l.name == r.name && l.artist_name == r.artist_name }
        listings << r
      end
    end

    results = []

    listings.each do |l|
      results << l.attributes.merge({ artist: l.artist_name.name })
    end

    render json: { status: 'success', listings: results }
  end

  def unfollow
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    artist = ArtistName.find_by(name: params[:artist])

    Following.where(user_id: user.id, artist_name_id: artist.id).destroy_all

    render json: { status: 'success', following: user_following(user) }
  end

  def follow
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end

    artist = ArtistName.find_by(name: params[:artist])

    Following.where(user_id: user.id, artist_name_id: artist.id).first_or_create

    render json: { status: 'success', following: user_following(user) }
  end

  private

  def user_following(user)
    following = []

    user.followings.each do |f|
      following << { artist: f.artist_name.name, notify_start: f.notify_start, notify_end: f.notify_end,
                     notify_listing: f.notify_listing, notify_edition: f.notify_edition }
    end
    following.sort_by { |f| f[:artist].downcase }
  end
end
