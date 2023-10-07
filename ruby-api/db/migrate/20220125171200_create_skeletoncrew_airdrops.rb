class CreateSkeletoncrewAirdrops < ActiveRecord::Migration[6.1]
  def change
    create_table :skeletoncrew_airdrops do |t|
      t.belongs_to :artist
      t.string :name
      t.string :description
      t.integer :supply
      t.string :image
      t.string :artist
      t.decimal :floor_price, precision: 20, scale: 9
      t.string :floor_mint
      t.integer :order_id
      t.timestamps
    end
  end
end