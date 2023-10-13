class CreateRestrictedUsernames < ActiveRecord::Migration[6.1]
  def change
    create_table :restricted_usernames do |t|
      t.string :name
      t.timestamps
    end
  end
end
