class CreateDiscordNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :discord_notifications do |t|
      t.string :name
      t.string :collection_name
      t.string :creator
      t.string :channel_id
      t.boolean :listings, default: true
      t.boolean :sales, default: true
      t.boolean :auctions, default: true
      t.boolean :bids, default: true
      t.timestamps
    end
  end
end
