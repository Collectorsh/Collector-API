class AddLockVersionToCurationListings < ActiveRecord::Migration[6.1]
  def change
    add_column :curation_listings, :lock_version, :integer, default: 0, null: false
  end
end

