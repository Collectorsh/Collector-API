class AddGalleryViewToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :gallery_view, :string, default: 'grid'
  end
end
