class CreateFollowings < ActiveRecord::Migration[6.1]
  def change
    create_table :followings do |t|
      t.belongs_to :user
      t.belongs_to :artist_name
      t.boolean :notify_start, default: true
      t.boolean :notify_end, default: true
      t.boolean :notify_listing, default: true
      t.boolean :notify_edition, default: true
      t.timestamps
    end
  end
end
