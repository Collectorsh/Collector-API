# frozen_string_literal: true

require 'httparty'
require 'json'
require_relative '../lib/metadata'

class AddMarketplaceListingJob < ApplicationJob
  queue_as :listing

  def perform(_type, amount, mint, owner, time, marketplace, seller, signature, account = nil)
    return if amount.nil?
    return if !signature.nil? && MarketplaceListing.find_by_signature(signature)

    if marketplace == 'collector' && MarketplaceListing.where(listed: true, mint: mint, seller: seller,
                                                              amount: amount, source: 'collector').first
      return
    end

    user = User.where("public_keys LIKE '%#{seller}%'").last

    user = User.find_by_id(user.parent_id) if user&.parent_id

    metadata = Metadata.find_pda(mint)
    creator = metadata[:creators][0]

    artist = ArtistName.where(public_key: creator).first_or_create

    resp = HTTParty.get(metadata[:uri]).body
    resp = JSON.parse(resp).symbolize_keys

    listing = MarketplaceListing.create(
      timestamp: time,
      name: resp[:name],
      source: marketplace,
      mint: mint,
      amount: amount,
      image: resp[:image],
      seller: seller,
      buyer: owner,
      signature: signature,
      creator: creator,
      account: account,
      artist_name_id: artist.id
    )

    listing.user_id = user.id if user
    listing.save!

    if user&.username
      message = "#{user.username} listed #{listing.name}"
      message += " by #{listing.artist_name.name} " if listing&.artist_name
      message += "for ◎#{listing.amount.to_f / 1_000_000_000}\n\n#{marketplace_link(listing)}"
      DISCORD.send_message(ENV['DISCORD_CHANNEL_ID'], message)
    end

    SendToDiscordJob.perform_later("listing", user, listing)
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
