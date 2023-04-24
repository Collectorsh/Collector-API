# frozen_string_literal: true

class RunFifteenMinutesJob < ApplicationJob
  queue_as :default

  def perform
    UpdateTwitterProfileImagesJob.perform_later unless already_running?('UpdateTwitterProfileImagesJob')

    RunFifteenMinutesJob.set(wait: 15.minutes).perform_later
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
