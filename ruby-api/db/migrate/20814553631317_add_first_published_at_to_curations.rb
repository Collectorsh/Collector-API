class AddFirstPublishedAtToYourTableName < ActiveRecord::Migration[6.1]  
  def change
    add_column :curations, :first_published_at, :date
  end
end


