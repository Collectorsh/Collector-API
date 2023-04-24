class CreateMints < ActiveRecord::Migration[6.1]
  def change
    create_table :mints do |t|
      t.belongs_to :user
      t.string :name
      t.string :description
      t.string :image
      t.string :uri
      t.string :symbol
      t.string :mint
      t.string :address
      t.string :collection
      t.string :edition_type
      t.string :supply
      t.string :max_supply
      t.string :print
    end
  end
end
