class CreateUserFollowings < ActiveRecord::Migration[6.1]
  def change
    create_table :user_followings do |t|
      t.belongs_to :user
      t.integer :following_id
      t.timestamps
    end
  end
end
