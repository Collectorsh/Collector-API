class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :username
      t.string :email
      t.string :public_key
      t.string :twitter_profile_image
      t.timestamp :twitter_image_updated_at
      t.timestamps
    end
    add_index :users, :public_key
    add_index :users, :username
  end
end
