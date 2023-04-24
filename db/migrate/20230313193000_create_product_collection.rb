class CreateProductCollection < ActiveRecord::Migration[6.1]
  def change
    create_table :product_collections do |t|
      t.string :name
      t.string :image
    end
  end
end
