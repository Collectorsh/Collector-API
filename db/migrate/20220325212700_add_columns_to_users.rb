class AddColumnsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :border, :boolean, default: true
    add_column :users, :description, :boolean, default: true
    add_column :users, :shadow, :boolean, default: true
    add_column :users, :rounded, :boolean, default: true
  end
end
