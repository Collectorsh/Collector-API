# frozen_string_literal: true

class SignatureController < ApplicationController
  def listings
    holders = TokenMint.pluck(:user_id)
    listings = MarketplaceListing.select('marketplace_listings.*, users.username, users.twitter_profile_image as username_twitter')
                                 .where(user_id: holders)
                                 .where("listed = true")
                                 .where("mint IS NOT NULL AND image IS NOT NULL AND amount IS NOT NULL AND artist_name IS NOT NULL")
                                 .where("creator != seller")
                                 .joins(:user)

    results = []

    listings.each do |l|
      results << l.attributes.merge({ artist: l.artist_name.name })
    end

    render json: { status: 'success', listings: results }
  end
end
