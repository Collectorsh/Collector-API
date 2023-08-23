class CreateKeyHashes < ActiveRecord::Migration[6.1]
  def change
    create_table :key_hashes do |t|
      t.string :name, null: false, unique: true
      t.string :hash, null: false
      t.timestamps
    end
  end
end
