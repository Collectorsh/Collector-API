class AddDefaultVisibilityToUsers < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :default_visibility, :boolean, default: false
  end

  def down
    drop_column :users, :default_visibility
  end
end
