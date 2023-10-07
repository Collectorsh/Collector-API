class AddSubscriptionEndToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :subscription_end, :timestamp
  end
end
