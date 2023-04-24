class CreateBids < ActiveRecord::Migration[6.1]
  def change
    create_table :bids do |t|
      t.belongs_to :user
      t.belongs_to :auction
      t.integer :bid, limit: 5
      t.integer :end_time, limit: 5
      t.timestamps
    end
  end
end
