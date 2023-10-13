class CreateKeys < ActiveRecord::Migration[6.1]
  def change
    create_table :keys do |t|
      t.belongs_to :user
      t.string :api_key
      t.string :nonce
      t.boolean :active, default: false
      t.timestamps
    end
  end
end
