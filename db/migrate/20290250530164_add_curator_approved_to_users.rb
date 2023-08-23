class AddCuratorApprovedAndCurationIdsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :curator_approved, :boolean, default: false
  end
end
