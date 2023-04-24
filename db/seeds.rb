# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'csv'

artists = CSV.read('./db/artists.csv', liberal_parsing: true)
artists.each do |row|
  SkeleArtist.create(name: row[0])
end

# airdrops = CSV.read('./db/airdrops.csv', liberal_parsing: true)
# airdrops.each do |row|
#   artist = Artist.find_by_name(row[4])
#   artist.airdrops.create(
#     name: row[0],
#     description: row[1],
#     supply: row[2],
#     image: row[3]
#   )
# end
