# frozen_string_literal: true

require 'httparty'
require 'json'

class UpdateExchangeJob < ApplicationJob
  queue_as :exchange

  def perform
    response = fetch_from_exchange(0)
    add_to_db(response['contractGroups'])
    remaining = response['totalGroups'] - 20
    from = 20
    while remaining.positive?
      response = fetch_from_exchange(from)
      add_to_db(response['contractGroups'])
      remaining -= 20
      from += 20
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end

  def fetch_from_exchange(from)
    result = HTTParty.get("https://api.exchange.art/v2/mints/contracts?from=#{from}&limit=20&sort=auctions-trending")
    result.parsed_response
  end

  def add_to_db(groups)
    groups.each do |group|
      # next unless auction['tokenPreviewData']['collection']['isOneOfOne']
      # next if auction['tokenPreviewData']['collection']['isNsfw']
      auction = group['availableContracts']['auctions'][0]
      next unless auction['data']['start'] < Time.now.to_i

      new_auction = false
      row = Auction.where(mint: auction['keys']['mint'], source: 'exchange').first

      unless row
        row = Auction.create(mint: auction['keys']['mint'], source: 'exchange')
        new_auction = true
      end

      if (artist = ArtistName.find_by(name: group['mint']['brand']['name']))
        user = User.where("public_keys like '%#{artist.public_key}%'").first
        row.seller = artist.public_key
        row.user_id = user.id if user && artist.public_key
      else
        artist = ArtistName.create!(name: group['mint']['brand']['name'])
        metadata = Metadata.find_pda(auction['keys']['mint'])
        creator = metadata[:creators][0]
        artist.update_attribute :public_key, creator
      end

      row.artist_name_id = artist.id
      row.start_time = auction['data']['start']
      row.end_time = auction['data']['end']
      row.reserve = auction['data']['reservePrice']
      row.min_increment = auction['data']['minimumIncrement']
      row.ending_phase = auction['data']['endingPhase']
      row.extension = auction['data']['extensionWindow']
      row.highest_bid = auction['data']['highestBid']
      row.highest_bidder = auction['data']['highestBidder']
      row.number_bids = auction['data']['numberBids']
      row.brand_id = group['mint']['brand']['id']
      row.brand_name = group['mint']['brand']['name']
      row.collection_id = group['mint']['collection']['id']
      row.collection_name = group['mint']['collection']['name']
      row.image = group['mint']['image']
      row.name = group['mint']['name']
      # row.secondary = auction['tokenPreviewData']['analytics']['lastSale'].nil? ? false : true
      row.save

      SendToDiscordJob.perform_later("auction_start", nil, row) if new_auction
    end
  end
end
