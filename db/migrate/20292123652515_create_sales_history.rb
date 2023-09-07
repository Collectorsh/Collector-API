class CreateSalesHistory < ActiveRecord::Migration[6.1]
  def change
    create_table :sales_history do |t|
      t.string :source, default: 'Collector'
      t.references :curation, foreign_key: true
      t.numeric :price, null: false
      t.boolean :is_primary_sale, default: false
      t.string :sale_type, null: false # "edition_mint", "buy_now", "auction-{type}"
      t.string :tx_hash, null: false, unique: true
      t.string :token_mint, null: false
      t.string :token_name
      t.string :buyer_address, null: false
      t.references :buyer, foreign_key: { to_table: :users }
      t.string :seller_address, null: false
      t.references :seller, foreign_key: { to_table: :users }
      t.string :artist_address, null: false
      t.references :artist, foreign_key: { to_table: :users }
      t.boolean :is_edition, default: false
      t.string :image
      t.integer :editions_minted

      t.timestamps
    end
  end
end
