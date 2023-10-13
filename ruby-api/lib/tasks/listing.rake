namespace :listing do
  task estimate: :environment do
    MarketplaceListing.where(listed: true).where("estimate IS NULL").order(id: :asc).each do |listing|
      estimate = Estimate.check_exchange(listing.mint)
      estimate ||= Estimate.check_db(listing.mint)
      estimate ||= Estimate.check_magic_eden(listing.mint)
      listing.update_attribute :estimate, estimate
      puts "updated #{listing.id}"
    rescue StandardError => e
      puts e.message
    end
  end
end
