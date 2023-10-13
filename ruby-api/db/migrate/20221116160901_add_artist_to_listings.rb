class AddArtistToListings < ActiveRecord::Migration[6.1]
  def change
    add_column :marketplace_listings, :artist_name_id, :integer
  end
end
