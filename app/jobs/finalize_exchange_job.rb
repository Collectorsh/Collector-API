# frozen_string_literal: true

require 'httparty'
require 'json'

class FinalizeExchangeJob < ApplicationJob
  queue_as :exchange

  def perform
    Auction.where("start_time < #{(Time.now - 5.minutes).to_i} AND end_time < #{(Time.now - 10.minutes).to_i} AND end_time > #{(Time.now - 1.day).to_i} AND finalized = false AND source = 'exchange'").each do |row|
      response = fetch_from_exchange(row['mint'])
      update_sale(response['activities'][0], row) unless response.nil?
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end

  def update_sale(sale, row)
    return if sale.nil?

    row.highest_bid = sale['data']['amount']
    row.highest_bidder = sale['data']['nftReceiver']
    row.finalized = true
    row.save

    # SendToDiscordJob.perform_later("auction_end", nil, row)
  end

  def fetch_from_exchange(mint)
    result = HTTParty.get("#{ENV['EXCHANGE_SALES']}?filters[activityGroup]=sales&filters[mintPubKey]=#{mint}&from=0&limit=1",
                          headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
    result.parsed_response
  end
end
