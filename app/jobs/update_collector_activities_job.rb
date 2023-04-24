# frozen_string_literal: true

require 'httparty'
require 'json'

class UpdateCollectorActivitiesJob < ApplicationJob
  queue_as :collector

  def perform
    response = Holaplex::Client.query(ActivitiesQuery::Activities,
                                      variables: { auctionHouses: %w[3nAR6ZWZQA1uSNcRy3Qya2ihLU9dhaWKfZavoSiRrXzj
                                                                     A5CsrtsB6K8DCfFf86jQhpaLSmrYAy38r89JAy73jGGw] })
    response.data.activities.each do |a|
      case a.activity_type
      # when 'listing'
      #   time = Time.parse(a.created_at).to_i
      #   amount = a.price
      #   mint = a.nft.mint_address
      #   owner = a.wallets[0].address
      #   seller = a.wallets[0].address
      #   AddMarketplaceListingJob.perform_later('listing', amount, mint, owner, time, 'collector', seller, nil)
      when 'purchase'
        time = Time.parse(a.created_at).to_i
        amount = a.price
        mint = a.nft.mint_address
        owner = a.wallets[1].address
        seller = a.wallets[0].address
        AddMarketplaceSaleJob.perform_later('buy', amount, mint, owner, time, 'collector', seller, nil)
      end
    end
  rescue StandardError => e
    Rails.logger.error e.message
    Bugsnag.notify(e)
  end
end
