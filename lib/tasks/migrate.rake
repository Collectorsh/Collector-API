namespace :migrate do
  task followings: :environment do
    Follow.all.each do |f|
      a = ArtistName.find_by(name: f.artist)
      next unless a

      user = f.user
      next unless user

      Following.where(user_id: user.id, artist_name_id: a.id, notify_start: f.notify_start, notify_end: f.notify_end,
                      notify_listing: f.notify_listing, notify_edition: f.notify_edition).first_or_create
    end
  end
end
