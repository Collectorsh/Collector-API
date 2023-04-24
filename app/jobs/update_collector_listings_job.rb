# frozen_string_literal: true

require 'httparty'
require 'json'

class UpdateCollectorListingsJob < ApplicationJob
  queue_as :collector

  def perform
    resp = HTTParty.post("#{ENV['COLLECTOR_API']}/listings", timeout: 300,
                                                             headers: { 'Content-Type' => 'application/json' })
    listings = resp['listings']

    MarketplaceListing.where(source: 'collector', listed: true).each do |ml|
      results = listings.filter { |listing| listing['mint'] == ml.mint }
      next if results.find { |l| ml.seller == l['seller'] && l['price'] == ml.amount.to_i }

      ml.update_attribute :listed, false
    end
    # Temp solution until the activities query is working again
    listings.each do |listing|
      time = listing['created']
      amount = listing['price']
      mint = listing['mint']
      owner = listing['seller']
      seller = listing['seller']
      AddMarketplaceListingJob.perform_later('listing', amount, mint, owner, time, 'collector', seller, nil)
    end
  end
end
