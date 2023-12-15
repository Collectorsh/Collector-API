class CreateMintedIndexer < ActiveRecord::Migration[6.1]
  def change
    create_table :minted_indexer do |t|
      t.string :mint, null: false, unique: true
      t.string :name, null: false
      t.integer :owner_id
      t.string :owner_address, null: false
      t.integer :artist_id
      t.string :artist_address, null: false
      t.string :animation_url
      t.string :image
      t.string :description
      t.boolean :primary_sale_happened
      t.boolean :is_edition, default: false
      t.string :parent 
      t.boolean :is_master_edition, default: false
      t.integer :supply
      t.integer :max_supply
      t.jsonb :creators
      t.json :files
      t.integer :royalties
      t.boolean :is_collection_nft
      t.string :nft_state

      t.timestamps
    end

    add_index :minted_indexer, :mint, unique: true
    add_foreign_key :minted_indexer, :users, column: :artist_id
    add_foreign_key :minted_indexer, :users, column: :owner_id
  end
end
