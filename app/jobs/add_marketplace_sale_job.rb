# frozen_string_literal: true

require 'httparty'
require 'json'
require_relative '../lib/metadata'

class AddMarketplaceSaleJob < ApplicationJob
  queue_as :sale

  def perform(type, amount, mint, owner, time, marketplace, seller, signature, subdomain = nil)
    return if !signature.nil? && MarketplaceSale.find_by_signature(signature)

    if marketplace == 'collector' && MarketplaceSale.where(mint: mint, seller: seller,
                                                           amount: amount, source: 'collector').first
      return
    end

    user = User.where("public_keys LIKE '%#{owner}%'").last

    user = User.find_by_id(user.parent_id) if user&.parent_id

    metadata = Metadata.find_pda(mint)
    return unless metadata

    creator = metadata[:creators][0]

    artist = ArtistName.where(public_key: creator).first_or_create

    resp = HTTParty.get(metadata[:uri]).body
    resp = JSON.parse(resp).symbolize_keys

    sale = MarketplaceSale.create(
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
      transaction_type: type,
      subdomain: subdomain,
      artist_name_id: artist.id
    )

    sale.user_id = user.id if user
    sale.save!

    if user&.username && type != 'auction'
      message = "#{user.username} purchased #{sale.name} by #{sale.artist_name.name}"
      message += " for ◎#{sale.amount.to_f / 1_000_000_000}"
      message += "\n\n#{marketplace_link(sale)}"
      DISCORD.send_message(ENV['DISCORD_CHANNEL_ID'], message)
    end

    SendToDiscordJob.perform_later("sale", user, sale) unless type == 'auction'
    NotifyNewEditionJob.perform_later(sale) if type == 'edition'
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
