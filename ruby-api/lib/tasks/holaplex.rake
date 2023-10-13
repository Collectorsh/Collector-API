namespace :holaplex do
  task update: :environment do
    UpdateHolaplexActivitiesJob.perform_now
  end

  task finalize: :environment do
    FinalizeHolaplexJob.perform_now
  end

  task image: :environment do
    ImageFromUriJob.perform_now
  end
end
