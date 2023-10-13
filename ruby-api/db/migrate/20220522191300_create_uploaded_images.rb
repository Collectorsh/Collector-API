class CreateUploadedImages < ActiveRecord::Migration[6.1]
  def change
    create_table :uploaded_images do |t|
      t.string :mint
      t.boolean :success, default: true
      t.timestamps
    end
    add_index :uploaded_images, :mint
  end
end
