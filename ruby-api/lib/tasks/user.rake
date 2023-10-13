namespace :user do
  task auctions: :environment do
    User.where("username IS NOT NULL").each do |user|
      public_keys = user.public_keys
      Auction.where(finalized: true, highest_bidder: public_keys).each do |auction|
        puts "#{user.username} won #{auction.name} for #{auction.highest_bid.to_f / 1_000_000_000} sol"
      end
    end
  end
end
