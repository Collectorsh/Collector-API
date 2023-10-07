# frozen_string_literal: true

class WatchlistController < ApplicationController
  def collectors
    results = []
    Watchlist.all.each do |user|
      auctions = []
      user.watchlist_bids.where("watchlist_bids.end_time > #{Time.now.to_i}").each do |bid|
        auction = Auction.find_by_id(bid.auction_id)
        winning = auction.highest_bid == bid.bid ? 'yes' : 'no'
        auctions << auction.attributes.merge({ bid: bid.bid })
      end
      results << [user, auctions]
    end
    render json: results
  end

  def artists
    artists = WatchlistArtist.all.collect { |artist| artist.name.gsub(' ', '%') + '%' }
    auctions = Auction.where("end_time > #{Time.now.to_i}").where('"brand_name"' +
      " ILIKE ANY ( array[?] )", artists)

    render json: auctions
  end

  def bids
    auctions = []
    WatchlistBid.where("end_time > #{Time.now.to_i}").order(end_time: :asc).each do |bid|
      auction = Auction.find_by_id(bid.auction_id)
      bidder = Watchlist.find_by_id(bid.watchlist_id)
      auctions << auction.attributes.merge({ bid: bid.bid, username: bidder.name, twitter: bidder.twitter,
                                             twitter_image: bidder.image })
    end
    results = []
    auctions.each do |auction|
      begin
        auction['twitter_profile_image'] = TWITTER.user(auction[:twitter].split('/').last).profile_image_uri.to_s
      rescue StandardError => e
        Rails.logger.error e.message
      end
      if result = results.find { |result| result['id'] == auction['id'] }
        # already exists in the results array
        if auction[:bid] > result[:bid]
          results = results.reject { |result| result['id'] == auction['id'] }
          results << auction
        end
      else
        results << auction
      end
    end
    render json: results
  end
end
