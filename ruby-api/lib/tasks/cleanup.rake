namespace :cleanup do
  task auctions: :environment do
    # Reset auctions and sales that have finalized before their end_time
    Auction.where(finalized: true).where("end_time > ?", Time.now.to_i).each do |a|
      a.update_attribute :finalized, false
    end
    Sale.where("end_time > ?", Time.now.to_i).each(&:delete)
  end

  task images: :environment do
    UploadedImage.where(success: false).destroy_all
  end

  task artists: :environment do
    DiscordNotification.all.each do |d|
      artists = []
      missing = []
      d.artists.each do |da|
        a = ArtistName.where("name ilike '#{da.gsub(' ', '%')}%'")
        if a.first
          artists << a.first.name
        else
          missing << da
        end
      end
      d.update_attribute :artists, artists
      puts artists.inspect
      puts missing.inspect
    end
  end
end
