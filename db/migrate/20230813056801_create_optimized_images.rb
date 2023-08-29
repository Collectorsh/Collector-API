class CreateOptimizedImages < ActiveRecord::Migration[6.1]
  def change
    create_table :optimized_images do |t|
      t.string :cld_id, unique: true
      t.string :mint_address, unique: true
      t.string :optimized
      t.string :error_message
      t.timestamps
    end
  end
end