class CreateArtistNames < ActiveRecord::Migration[6.1]
  def change
    create_table :artist_names do |t|
      t.string :public_key
      t.string :name
      t.string :collection
      t.string :source
      t.string :twitter
      t.timestamp :twitter_image_updated_at
      t.timestamps
      t.integer :artist_id
    end
    add_index :artist_names, :public_key
    add_index :artist_names, :name
    add_index :artist_names, :collection
    add_index :artist_names, :source
    add_foreign_key :artist_names, :users, column: :artist_id
  end
end
