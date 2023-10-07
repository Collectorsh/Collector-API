class AddRequiredCollection < ActiveRecord::Migration[6.1]
  def change
    add_column :drops, :required_collection, :string
  end
end
