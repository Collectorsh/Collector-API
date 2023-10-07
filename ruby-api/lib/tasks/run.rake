namespace :run do
  task all: :environment do
    RunThirtySecondsJob.perform_now
    RunOneMinuteJob.perform_now
    RunFiveMinutesJob.perform_now
    RunFifteenMinutesJob.perform_now
    RunOneHourJob.perform_now
  end
end
