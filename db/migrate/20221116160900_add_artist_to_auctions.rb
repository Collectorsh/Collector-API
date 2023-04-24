class AddArtistToAuctions < ActiveRecord::Migration[6.1]
  def change
    add_column :auctions, :artist_name_id, :integer
  end
end
