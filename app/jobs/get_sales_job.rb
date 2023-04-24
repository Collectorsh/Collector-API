# frozen_string_literal: true

class GetSalesJob < ApplicationJob
  queue_as :notification

  def perform
    User.where("username IS NOT NULL").each do |user|
      public_keys = user.public_keys
      Auction.where(finalized: true, highest_bidder: public_keys)
             .where("number_bids > 0").where("end_time > #{(Time.now - 1.day).to_i}")
             .each do |auction|
        next if Sale.find_by_mint(auction.mint)

        Sale.create!(
          user_id: user.id,
          end_time: auction.end_time,
          highest_bid: auction.highest_bid,
          number_of_bids: auction.number_bids,
          mint: auction.mint,
          name: auction.name,
          brand_name: auction.brand_name,
          collection_name: auction.collection_name,
          image: auction.image,
          source: auction.source,
          metadata_uri: auction.metadata_uri,
          highest_bidder_username: auction.highest_bidder_username
        )
      end
    end
  rescue StandarError => e
    Bugsnag.notify(e)
  end
end
