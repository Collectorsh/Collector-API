# frozen_string_literal: true

class UpdateBidsJob < ApplicationJob
  queue_as :default

  def perform
    update_user_bids
    update_collection_bids
    update_artist_bids
  rescue StandardError => e
    Bugsnag.notify(e)
  end

  private

  def update_collection_bids
    DiscordNotification.where(bids: true).each do |dis|
      Auction.where("end_time > #{(Time.now - 10.minutes).to_i} AND source = 'exchange'")
             .where("collection_name = '#{dis.collection_name}' AND collection_name IS NOT NULL").each do |auction|
        bid = DiscordBid.where(discord_notification_id: dis.id, auction_id: auction.id).first_or_create
        current_bid = bid.bid || 0
        next unless auction.highest_bid > current_bid

        bid.bid = auction.highest_bid
        bid.end_time = auction.end_time
        bid.save!

        SendToDiscordJob.perform_later("bid", nil, bid)
      end
    end
  end

  def update_artist_bids
    DiscordNotification.where(bids: true).each do |dis|
      Auction.where("end_time > #{(Time.now - 10.minutes).to_i}")
             .where(brand_name: dis.artists)
             .where("brand_name IS NOT NULL").each do |auction|
        bid = DiscordBid.where(discord_notification_id: dis.id, auction_id: auction.id).first_or_create
        current_bid = bid.bid || 0
        next unless auction.highest_bid > current_bid

        bid.bid = auction.highest_bid
        bid.end_time = auction.end_time
        bid.save!

        SendToDiscordJob.perform_later("bid", nil, bid)
      end
    end
  end

  def update_user_bids
    User.where("username IS NOT NULL").each do |user|
      user.public_keys.each do |public_key|
        Auction.where("end_time > #{(Time.now - 10.minutes).to_i} AND highest_bidder = '#{public_key}'").each do |auction|
          user = User.find_by_id(user.parent_id) if user.parent_id
          bid = Bid.where(user_id: user.id, auction_id: auction.id).first_or_create
          current_bid = bid.bid || 0
          next unless auction.highest_bid > current_bid

          bid.outbid = false
          bid.bid = auction.highest_bid
          bid.end_time = auction.end_time
          bid.save!

          brand = auction.brand_name
          message = "New bid by #{user.username} for ◎#{auction.highest_bid.to_f / 1_000_000_000}"
          message += "\n\n#{auction.name} by #{brand}\n\n#{marketplace_link(auction)}"

          DISCORD.send_message(ENV['DISCORD_CHANNEL_ID'], message)
        end
      end
    end
  end
end
