class AddNonceToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :nonce, :string
    add_column :users, :api_key, :string
  end
end
