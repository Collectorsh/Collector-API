class CreateCurationHighlights < ActiveRecord::Migration[6.1]
  def change
    create_table :curation_highlights do |t|
      t.string :name, null: false, unique: true
      t.integer :curation_ids, array: true, default: []
    end
  end
end
