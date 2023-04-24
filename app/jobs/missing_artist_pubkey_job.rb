# frozen_string_literal: true

require 'httparty'
require 'json'

class MissingArtistPubkeyJob < ApplicationJob
  queue_as :artist

  def perform
    ArtistName.where("public_key IS NULL").each do |row|
      result = Auction.where(brand_name: row.name).last
      result ||= MarketplaceSale.where(artist_name_id: row.id).last
      next unless result

      metadata = Metadata.find_pda(result.mint)
      next if metadata.nil?

      creator = metadata[:creators][0]
      row.public_key = creator
      row.save!
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
