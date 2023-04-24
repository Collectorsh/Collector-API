# frozen_string_literal: true

class RunOneHourJob < ApplicationJob
  queue_as :default

  def perform
    UpdateArtistTwitterJob.perform_later unless already_running?('UpdateArtistTwitterJob')
    # UpdateArtistNamesJob.perform_later unless already_running?('UpdateArtistNamesJob')

    MintVisibility.where("image IS NULL AND mint_address IS NOT NULL AND visible = true").each do |mv|
      UpdateMintVisibilityImageUrisJob.perform_later(mv)
    end

    RunOneHourJob.set(wait: 1.hour).perform_later
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
