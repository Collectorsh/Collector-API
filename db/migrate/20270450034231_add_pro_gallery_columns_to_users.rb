class AddProGalleryColumnsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :banner_image, :string
    add_column :users, :socials, :jsonb
    add_column :users, :subscription_level, :string
  end
end
