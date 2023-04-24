# frozen_string_literal: true

class AuctionsController < ApplicationController
  def get
    render json: Auction.where(finalized: false).where("end_time > '#{Time.now.to_i}' AND end_time < '#{(Time.now + 1.day).to_i}'").order(end_time: :asc)
  end

  def live
    auctions = Auction.select('auctions.*, users.username, users.twitter_profile_image')
                      .where("end_time > #{Time.now.to_i}")
                      .where("end_time < #{(Time.now + 1.day).to_i}")
                      .where("users.username IS NOT NULL")
                      .order("users.token_holder desc")
                      .order(number_bids: :desc)
                      .joins(:user).limit(5)

    render json: auctions.to_json
  end
end
