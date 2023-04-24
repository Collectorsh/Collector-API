class CreateTokenMints < ActiveRecord::Migration[6.1]
  def change
    create_table :token_mints do |t|
      t.string :mint
      t.string :owner
      t.timestamps
    end
  end
end
