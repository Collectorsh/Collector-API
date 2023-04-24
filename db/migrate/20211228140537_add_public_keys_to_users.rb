class AddPublicKeysToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :public_keys, :text
  end
end
