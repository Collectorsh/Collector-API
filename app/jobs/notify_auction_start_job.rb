# frozen_string_literal: true

class NotifyAuctionStartJob < ApplicationJob
  queue_as :notification

  def perform
    auctions = Auction.where(notified_start: false, finalized: false)
                      .where("end_time > #{Time.now.to_i} AND start_time < #{Time.now.to_i}")
                      .where("mint IS NOT NULL")

    auctions.each do |auction|
      auction.update_attribute :notified_start, true

      message = "New auction started. #{auction.name} by #{auction.brand_name}\n"
      message += "Reserve of ◎#{(auction.reserve.to_f / 1_000_000_000).round(2)}\n" if auction.reserve
      message += marketplace_link(auction)

      user_ids = []

      artist = ArtistName.find_by(name: auction.brand_name)
      next unless artist

      Following.where(artist_name_id: artist.id)
               .where(notify_start: true).each do |f|
        next if user_ids.include? f.user.id
        next unless f.user.token_holder

        user_ids << f.user.id
        next unless f.user.notify_email && f.user.email

        SendToUserEmailJob.perform_now(f.user.email, 'Auction started', message, auction.image)
      end
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
