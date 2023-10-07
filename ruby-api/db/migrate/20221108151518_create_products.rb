class CreateProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :description
      t.integer :price_usd_cents
      t.boolean :gated, default: false
      t.string :mint_list_name
      t.integer :holder_discount
      t.boolean :active, default: false
      t.string :image
      t.string :uuid
      t.timestamps
    end
  end
end
