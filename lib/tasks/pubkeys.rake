namespace :pub_keys do
  task :migrate => :environment do
    User.all.each do |u|
      u.public_keys = [u.public_key]
      u.save!
    end
  end
end
