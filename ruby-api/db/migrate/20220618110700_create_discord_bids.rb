class CreateDiscordBids < ActiveRecord::Migration[6.1]
  def change
    create_table :discord_bids do |t|
      t.belongs_to :auction
      t.belongs_to :discord_notification
      t.integer :bid, limit: 5
      t.integer :end_time, limit: 5
      t.timestamps
    end
  end
end
