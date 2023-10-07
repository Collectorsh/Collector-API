class AddArtistsToDiscordNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :discord_notifications, :artists, :text
  end
end
