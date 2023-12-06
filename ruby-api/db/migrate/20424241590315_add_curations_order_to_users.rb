class AddCurationOrderToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :curations_order, :jsonb, default: []
  end
end

