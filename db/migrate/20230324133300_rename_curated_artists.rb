class RenameCuratedArtists < ActiveRecord::Migration[6.1]
  def change
    rename_column :users, :curated_artists, :allowed_users
  end
end
