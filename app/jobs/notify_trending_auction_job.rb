# frozen_string_literal: true

class NotifyTrendingAuctionJob < ApplicationJob
  queue_as :notification

  def perform
    auctions = Auction.where(notified_trending: false, finalized: false)
                      .where("end_time > #{Time.now.to_i} AND number_bids >= 5")
                      .where("mint IS NOT NULL")

    auctions.each do |auction|
      auction.update_attribute :notified_trending, true

      User.where(notify_trending: true).each do |u|
        message = "Trending auction alert.  #{auction.name} by #{auction.brand_name} has #{auction.number_bids} bids with a highest bid of ◎#{(auction.highest_bid.to_f / 1_000_000_000).round(2)}\n
                  #{marketplace_link(
                    auction
                  )}"
        next unless u.notify_email && u.email

        SendToUserEmailJob.perform_now(u.email, 'Trending auction', message, auction.image)
      end
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
