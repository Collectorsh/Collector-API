class CreateHubs < ActiveRecord::Migration[6.1]
  def change
    create_table :hubs do |t|
      t.belongs_to :user
      t.string :name
      t.string :description
      t.string :auction_house
      t.string :basis_points
      t.string :wallet
    end
  end
end
