class AddArtistToSales < ActiveRecord::Migration[6.1]
  def change
    add_column :marketplace_sales, :artist_name_id, :integer
  end
end
