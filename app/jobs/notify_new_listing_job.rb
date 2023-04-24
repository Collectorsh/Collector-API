# frozen_string_literal: true

class NotifyNewListingJob < ApplicationJob
  queue_as :notification

  def perform
    listings = MarketplaceListing.where(notified: false, listed: true)
                                 .where("mint IS NOT NULL")

    listings.each do |listing|
      listing.update_attribute :notified, true
      next unless listing.artist_name

      message = "New Buy Now Listing. #{listing.name} by #{listing.artist_name.name}\n"
      message += "Buy Now price of ◎#{(listing.amount.to_f / 1_000_000_000).round(2)}\n"
      message += marketplace_link(listing)

      user_ids = []

      Following.where(artist_name_id: listing.artist_name.id)
               .where(notify_listing: true).each do |f|
        next unless f.user.token_holder
        next if user_ids.include? f.user.id

        user_ids << f.user.id
        next unless f.user.notify_email && f.user.email

        SendToUserEmailJob.perform_now(f.user.email, 'New Buy Now Listing', message, listing.image)
      end
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
