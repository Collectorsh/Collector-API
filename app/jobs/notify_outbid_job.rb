# frozen_string_literal: true

class NotifyOutbidJob < ApplicationJob
  queue_as :notification

  def perform
    Bid.where(outbid: false).where("end_time > #{Time.now.to_i}").each do |bid|
      auction = Auction.find_by_id(bid.auction_id)
      next if auction.highest_bid == bid.bid

      bid.update_attribute :outbid, true
      user = bid.user
      user = User.find_by_id(user.parent_id) if user.parent_id

      message = "You were outbid on #{auction.name} by #{auction.brand_name}\n\n"
      message += "New Highest bid is ◎#{(auction.highest_bid.to_f / 1_000_000_000).round(2)}"
      message += "\n#{marketplace_link(
        auction
      )}"
      next unless user.email && user.notify_email

      SendToUserEmailJob.perform_now(user.email, 'You have been outbid', message, auction.image)
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
