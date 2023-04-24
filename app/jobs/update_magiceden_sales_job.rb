# frozen_string_literal: true

require 'httparty'
require 'json'

class UpdateMagicedenSalesJob < ApplicationJob
  queue_as :magiceden

  def perform
    collections = Drop.where(market: true).pluck(:collection_address)
    url = "https://api.helius.xyz/v1/nft-events?api-key=#{ENV['HELIUS_API_KEY']}"
    query = { query: { sources: %w[MAGIC_EDEN EXCHANGE_ART], types: ["NFT_SALE"],
                       nftCollectionFilters: { verifiedCollectionAddress: collections } } }
    loop do
      resp = HTTParty.post(url, body: query.to_json,
                                headers: { 'Content-Type' => 'application/json' })
      results = resp['result']
      add_results(results) if results
      break # unless resp['paginationToken']

      query[:options] = {}
      query[:options][:limit] = 100
      query[:options][:paginationToken] = resp['paginationToken']
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end

  def add_results(results)
    results.each do |result|
      source = result['source'].downcase.gsub('_', '')
      source = 'exchange' if source == 'exchangeart'
      AddMarketplaceSaleJob.perform_later('buy', result['amount'], result['nfts'][0]['mint'], result['buyer'],
                                          result['timestamp'], source, result['seller'],
                                          result['signature'])
    end
  end
end
