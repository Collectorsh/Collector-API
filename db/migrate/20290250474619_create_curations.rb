class CreateCurations < ActiveRecord::Migration[6.1]
  def change
    create_table :curations do |t|
      t.integer :approved_artist_ids, array: true, default: []
      t.string :submitted_token_mints, array: true, default: []
      t.boolean :is_published, default: false
      t.string :name, null: false
      t.integer :curator_id, null: false
      t.json :published_content
      t.json :draft_content
      t.numeric :total_sales, default: 0
      t.numeric :curator_fee, null: false 
      t.string :auction_house_address, null: false
      t.string :private_key_hash, null: false
      # t.string :hydra_name, null: false
      t.string :payout_address, null: false

      t.timestamps
    end

    add_index :curations, :name, unique: true
    add_index :curations, :approved_artist_ids, using: 'gin' 
    add_foreign_key :curations, :users, column: :curator_id
  end
end
