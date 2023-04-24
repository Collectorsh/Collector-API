class AddCollectionId < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :collection_id, :integer
  end
end
