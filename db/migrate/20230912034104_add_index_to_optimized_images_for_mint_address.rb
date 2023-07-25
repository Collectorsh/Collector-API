class AddIndexToOptimizedImagesForMintAddress < ActiveRecord::Migration[6.1]
  def up
    execute 'CREATE INDEX index_optimized_images_on_mint_address ON optimized_images (mint_address)'
  end

  def down
    execute 'DROP INDEX index_optimized_images_on_mint_address'
  end
end