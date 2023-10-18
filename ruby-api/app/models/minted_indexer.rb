class MintedIndexer < ApplicationRecord
  self.table_name = "minted_indexer"

  belongs_to :artist, class_name: 'User', foreign_key: 'artist_id', optional: true
  belongs_to :owner, class_name: 'User', foreign_key: 'owner_id', optional: true
end