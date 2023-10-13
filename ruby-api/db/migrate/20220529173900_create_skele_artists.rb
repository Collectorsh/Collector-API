class CreateSkeleArtists < ActiveRecord::Migration[6.1]
  def change
    create_table :skele_artists do |t|
      t.string :name
      t.string :bio
      t.string :twitter_name
      t.integer :twitter_id
      t.string :twitter_image
      t.string :exchange
      t.string :holaplex
      t.string :website
      t.text :other_work
      t.timestamps
    end
  end
end