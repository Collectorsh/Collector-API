class CreateMintVisibility < ActiveRecord::Migration[6.1]
  def change
    create_table :mint_visibilities do |t|
      t.belongs_to :user
      t.string :mint_address
      t.boolean :visible, default: true
      t.timestamps
    end
  end
end
