class AddCuratorApprovedAndCurationIdsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :bio_delta, :json, 
  end
end
