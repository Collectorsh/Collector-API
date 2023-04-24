# frozen_string_literal: true

class RunOneMinuteJob < ApplicationJob
  queue_as :default

  def perform
    # UpdateFormfunctionSalesJob.perform_later unless already_running?('UpdateFormfunctionSalesJob')
    UpdateExchangeSalesJob.perform_later unless already_running?('UpdateExchangeSalesJob')

    NotifyNewListingJob.perform_later unless already_running?('NotifyNewListingJob')
    NotifyAuctionStartJob.perform_later unless already_running?('NotifyAuctionStartJob')
    NotifyAuctionEndJob.perform_later unless already_running?('NotifyAuctionEndJob')
    NotifyNewArtistAuctionJob.perform_later unless already_running?('NotifyNewArtistAuctionJob')
    NotifyOutbidJob.perform_later unless already_running?('NotifyOutbidJob')
    NotifyTrendingAuctionJob.perform_later unless already_running?('NotifyTrendingAuctionJob')

    RunOneMinuteJob.set(wait: 1.minute).perform_later
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
