class AddCuratedArtistsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :curated_artists, :text
  end
end
