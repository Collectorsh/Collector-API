class AddTwitterToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :twitter_oauth_token, :string
    add_column :users, :twitter_oauth_secret, :string
    add_column :users, :twitter_user_id, :string
    add_column :users, :twitter_screen_name, :string
  end
end
