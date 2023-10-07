class CreateFollows < ActiveRecord::Migration[6.1]
  def change
    create_table :follows do |t|
      t.belongs_to :user
      t.string :artist
      t.boolean :notify_start, default: true
      t.boolean :notify_end, default: true
      t.timestamps
    end
  end
end
