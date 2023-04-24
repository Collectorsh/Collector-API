# frozen_string_literal: true

class NotifyNewArtistAuctionJob < ApplicationJob
  queue_as :notification

  def perform
    auctions = Auction.where(notified_new_artist: false, finalized: false)
                      .where("end_time > #{Time.now.to_i}")
                      .where("mint IS NOT NULL")

    auctions.each do |auction|
      auction.update_attribute :notified_new_artist, true

      next if Auction.where("LOWER(REPLACE(brand_name, ' ', '')) = '#{auction.brand_name.gsub(' ',
                                                                                              '').downcase}'").count > 1

      message = "New Artist Auction. #{auction.name} by #{auction.brand_name}\n"
      message += "With a reserve of ◎#{(auction.reserve.to_f / 1_000_000_000).round(2)}\n" if auction.reserve
      message += marketplace_link(auction)

      User.where(notify_new_artist: true, notify_email: true).each do |u|
        next unless u.email

        SendToUserEmailJob.perform_now(u.email, 'New Artist auction', message, auction.image)
      end
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
