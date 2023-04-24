# frozen_string_literal: true

class RunThirtySecondsJob < ApplicationJob
  queue_as :default

  def perform
    # UpdateExchangeEditionsJob.perform_later unless already_running?('UpdateExchangeEditionsJob')

    RunThirtySecondsJob.set(wait: 30.seconds).perform_later
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
