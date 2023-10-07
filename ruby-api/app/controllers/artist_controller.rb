# frozen_string_literal: true

class ArtistController < ApplicationController
  def auctions
    auctions = []
    rows = Auction.where("end_time > ?",
                         Time.now.to_i)
    rows.each do |row|
      next unless (user = User.where("public_keys like '%#{row.artist_name.public_key}%'").first)

      user = user.attributes.except('api_key', 'nonce', 'twitter_oauth_secret',
                                    'twitter_oauth_token')

      auctions << { user: user, auction: row }
    end

    render json: auctions
  end
end
