# frozen_string_literal: true

class NotifyAuctionEndJob < ApplicationJob
  queue_as :notification

  def perform
    auctions = Auction.where(notified_end: false, finalized: false).where("end_time - #{Time.now.to_i} <= 1800")
                      .where("mint IS NOT NULL")

    auctions.each do |auction|
      auction.update_attribute :notified_end, true

      message = "#{auction.name} by #{auction.brand_name} is ending soon\n\n"
      message += if auction.highest_bid
                   "Highest bid of ◎#{(auction.highest_bid.to_f / 1_000_000_000).round(2)}"
                 else
                   "No bids yet"
                 end
      message += "\n#{marketplace_link(
        auction
      )}"

      user_ids = []

      artist = ArtistName.find_by(name: auction.brand_name)
      next unless artist

      Following.where(artist_name_id: artist.id)
               .where(notify_end: true).each do |f|
        next if user_ids.include? f.user.id
        next unless f.user.token_holder

        user_ids << f.user.id
        next unless f.user.notify_email && f.user.email

        SendToUserEmailJob.perform_now(f.user.email, 'Auction ending soon', message, auction.image)
      end
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
