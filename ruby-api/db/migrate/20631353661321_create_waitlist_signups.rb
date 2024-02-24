class CreateWaitlistSignups < ActiveRecord::Migration[6.1]
  def change
    create_table :waitlist_signups do |t|
      t.references :user, null: false, foreign_key: true
      t.string :twitter_handle
      t.string :email
      t.text :more_info

      t.timestamps
    end
  end
end

