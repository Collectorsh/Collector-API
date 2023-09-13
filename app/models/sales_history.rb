class SalesHistory < ApplicationRecord
  self.table_name = "sales_history"
  belongs_to :curation
  belongs_to :buyer, class_name: 'User', foreign_key: 'buyer_id', optional: true
  belongs_to :seller, class_name: 'User', foreign_key: 'seller_id', optional: true
  belongs_to :artist, class_name: 'User', foreign_key: 'artist_id', optional: true
end