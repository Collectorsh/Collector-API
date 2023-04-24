class AddMoreToDrops < ActiveRecord::Migration[6.1]
  def change
    add_column :drops, :active, :boolean, default: true
    add_column :drops, :lamports, :integer
  end
end
