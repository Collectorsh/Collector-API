# frozen_string_literal: true

require 'httparty'
require 'json'

class UpdateMagicedenListingsJob < ApplicationJob
  queue_as :magiceden

  def perform
    signatures = MarketplaceListing.where(source: "magiceden", listed: true).pluck(:signature)
    creators = Drop.where(market: true).pluck(:creator)
    # ZMB wave 1 creator address
    creators << "DGygonz7pn6AFrb1nUUyH3Bu5SVuuCSu38AZWT1cAC4B"
    url = "https://api.helius.xyz/v1/active-listings?api-key=#{ENV['HELIUS_API_KEY']}"
    resp = HTTParty.post(url, body: { query: { marketplaces: ["MAGIC_EDEN"], firstVerifiedCreators: creators } }.to_json,
                              headers: { 'Content-Type' => 'application/json' })
    results = resp['result']
    me_signatures = results.map { |r| r['activeListings'][0]['transactionSignature'] }
    (signatures - me_signatures).each do |s|
      MarketplaceListing.find_by(signature: s).update_attribute(:listed, false)
    end
    results.each do |result|
      AddMarketplaceListingJob.perform_later(nil, result['activeListings'][0]['amount'], result['mint'], nil,
                                             Time.now.to_i, "magiceden", result['activeListings'][0]['seller'],
                                             result['activeListings'][0]['transactionSignature'])
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
