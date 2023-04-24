class CreatePurchases < ActiveRecord::Migration[6.1]
  def change
    create_table :purchases do |t|
      t.belongs_to :user
      t.string :public_key
      t.string :signature
      t.integer :lamports, limit: 5
      t.integer :months
      t.boolean :verified, default: false
      t.text :result
      t.timestamps
    end
  end
end
