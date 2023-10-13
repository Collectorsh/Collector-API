class AddMoreColumnsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :name, :string
    add_column :users, :bio, :string
    add_column :users, :artist, :boolean, default: false
  end
end
