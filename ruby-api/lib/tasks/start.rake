namespace :start do
  task all_jobs: :environment do
    # GetMintOwnerJob.delay(run_at: 30.seconds.from_now).perform_later
    GetSalesJob.delay(run_at: 5.seconds.from_now).perform_later
    UpdateBidsJob.delay(run_at: 10.seconds.from_now).perform_later
    UpdateWatchlistBidsJob.delay(run_at: 15.seconds.from_now).perform_later
    NotifyAuctionStartJob.delay(run_at: 20.seconds.from_now).perform_later
    NotifyAuctionEndJob.delay(run_at: 25.seconds.from_now).perform_later
    RemoveProJob.delay(run_at: 35.seconds.from_now).perform_later
    NotifyNewArtistAuctionJob.delay(run_at: 40.seconds.from_now).perform_later
    NotifyOutbidJob.delay(run_at: 45.seconds.from_now).perform_later
    NotifyTrendingAuctionJob.delay(run_at: 50.seconds.from_now).perform_later
    UpdateArtistTwitterJob.delay(run_at: 5.seconds.from_now).perform_later
    UpdateArtistNamesJob.delay(run_at: 20.seconds.from_now).perform_later
  end
end
