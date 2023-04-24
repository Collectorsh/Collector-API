# frozen_string_literal: true

class RunFiveMinutesJob < ApplicationJob
  queue_as :default

  def perform
    UpdateExchangeJob.perform_later unless already_running?('UpdateExchangeJob')
    # UpdateFormfunctionJob.perform_later unless already_running?('UpdateFormfunctionJob')
    UpdateBidsJob.perform_later unless already_running?('UpdateBidsJob')
    FinalizeExchangeJob.perform_later unless already_running?('FinalizeExchangeJob')
    # FinalizeFormfunctionJob.perform_later unless already_running?('FinalizeFormfunctionJob')

    GetSalesJob.perform_later unless already_running?('GetSalesJob')
    GetMintOwnerJob.perform_later unless already_running?('GetMintOwnerJob')

    UpdateExchangeOffersJob.perform_later unless already_running?('UpdateExchangeOffersJob')
    UpdateCollectorActivitiesJob.perform_later unless already_running?('UpdateCollectorActivitiesJob')
    UpdateCollectorListingsJob.perform_later unless already_running?('UpdateCollectorListingsJob')

    MissingArtistPubkeyJob.perform_later unless already_running?('MissingArtistPubkeyJob')

    UpdateMagicedenListingsJob.perform_later unless already_running?('UpdateMagicedenListingsJob')
    UpdateMagicedenSalesJob.perform_later unless already_running?('UpdateMagicedenSalesJob')

    RunFiveMinutesJob.set(wait: 5.minutes).perform_later
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
