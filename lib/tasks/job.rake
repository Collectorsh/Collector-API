namespace :job do
  task run_all: :environment do
    Rake::Task["job:sales"].invoke
    Rake::Task["job:listing"].invoke
    Rake::Task["job:start"].invoke
    Rake::Task["job:end"].invoke
    Rake::Task["job:new"].invoke
    Rake::Task["job:outbid"].invoke
    Rake::Task["job:trending"].invoke
    Rake::Task["job:pro"].invoke
    Rake::Task["job:names"].invoke
    Rake::Task["job:bids"].invoke
    Rake::Task["job:watchlist"].invoke
    Rake::Task["job:finalize_exchange"].invoke
    Rake::Task["job:finalize_formfunction"].invoke
    Rake::Task["job:finalize_holaplex"].invoke
    Rake::Task["job:update_exchange"].invoke
    Rake::Task["job:update_formfunction"].invoke
    Rake::Task["job:image"].invoke
    Rake::Task["job:listings"].invoke
    Rake::Task["job:holder"].invoke
    Rake::Task["job:listing_estimate"].invoke
    Rake::Task["job:user_estimate"].invoke
  end

  def already_running?(klass)
    query = Delayed::Job.where("handler ilike '%#{klass}%'")
                        .where(failed_at: nil)
    query.any?
  end

  task listing_estimate: :environment do
    UpdateListingEstimatesJob.perform_later unless already_running?('UpdateListingEstimatesJob')
  end

  task user_estimate: :environment do
    UpdateUserEstimatesJob.perform_later unless already_running?('UpdateUserEstimatesJob')
  end

  task holder: :environment do
    GetMintOwnerJob.perform_later unless already_running?('GetMintOwnerJob')
  end

  task vis_images: :environment do
    MintVisibility.where("image IS NULL AND mint_address IS NOT NULL AND order_id = 1 AND visible = true").each do |mv|
      UpdateMintVisibilityImageUrisJob.perform_later(mv)
    end
  end

  task collector_listings: :environment do
    UpdateCollectorListingsJob.perform_later unless already_running?('UpdateCollectorListingsJob')
  end

  task collector_activities: :environment do
    UpdateCollectorActivitiesJob.perform_later unless already_running?('UpdateCollectorActivitiesJob')
  end

  task holaplex_activities: :environment do
    UpdateHolaplexActivitiesJob.perform_later unless already_running?('UpdateHolaplexActivitiesJob')
  end

  task formfunction_sales: :environment do
    UpdateFormfunctionSalesJob.perform_later unless already_running?('UpdateFormfunctionSalesJob')
  end

  task exchange_editions: :environment do
    UpdateExchangeEditionsJob.perform_later unless already_running?('UpdateExchangeEditionsJob')
  end

  task exchange_sales: :environment do
    UpdateExchangeSalesJob.perform_later unless already_running?('UpdateExchangeSalesJob')
  end

  task exchange_offers: :environment do
    UpdateExchangeOffersJob.perform_later unless already_running?('UpdateExchangeOffersJob')
  end

  task twitter_image: :environment do
    UpdateTwitterProfileImagesJob.perform_later unless already_running?('UpdateTwitterProfileImagesJob')
  end

  task sales: :environment do
    GetSalesJob.perform_later unless already_running?('GetSalesJob')
  end

  task start: :environment do
    NotifyAuctionStartJob.perform_later unless already_running?('NotifyAuctionStartJob')
  end

  task listing: :environment do
    NotifyNewListingJob.perform_later unless already_running?('NotifyNewListingJob')
  end

  task end: :environment do
    NotifyAuctionEndJob.perform_later unless already_running?('NotifyAuctionEndJob')
  end

  task new: :environment do
    NotifyNewArtistAuctionJob.perform_later unless already_running?('NotifyNewArtistAuctionJob')
  end

  task outbid: :environment do
    NotifyOutbidJob.perform_later unless already_running?('NotifyOutbidJob')
  end

  task trending: :environment do
    NotifyTrendingAuctionJob.perform_later unless already_running?('NotifyTrendingAuctionJob')
  end

  task pro: :environment do
    RemoveProJob.perform_later unless already_running?('RemoveProJob')
  end

  task names: :environment do
    UpdateArtistNamesJob.perform_later unless already_running?('UpdateArtistNamesJob')
  end

  task twitter: :environment do
    UpdateArtistTwitterJob.perform_later unless already_running?('UpdateArtistTwitterJob')
  end

  task bids: :environment do
    UpdateBidsJob.perform_later unless already_running?('UpdateBidsJob')
  end

  task watchlist: :environment do
    UpdateWatchlistBidsJob.perform_later unless already_running?('UpdateWatchlistBidsJob')
  end

  task finalize_exchange: :environment do
    FinalizeExchangeJob.perform_later unless already_running?('FinalizeExchangeJob')
  end

  task finalize_formfunction: :environment do
    FinalizeFormfunctionJob.perform_later unless already_running?('FinalizeFormfunctionJob')
  end

  task update_exchange: :environment do
    UpdateExchangeJob.perform_later unless already_running?('UpdateExchangeJob')
  end

  task update_formfunction: :environment do
    UpdateFormfunctionJob.perform_later unless already_running?('UpdateFormfunctionJob')
  end

  task finalize_holaplex: :environment do
    FinalizeHolaplexJob.perform_later unless already_running?('FinalizeHolaplexJob')
  end

  task image: :environment do
    ImageFromUriJob.perform_later unless already_running?('ImageFromUriJob')
  end

  task listings: :environment do
    UpdateListingsJob.perform_later unless already_running?('UpdateListingsJob')
  end
end
