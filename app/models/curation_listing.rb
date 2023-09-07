class CurationListing < ApplicationRecord
  belongs_to :curation
  belongs_to :artist, class_name: 'User', foreign_key: 'artist_id', optional: true
  belongs_to :owner, class_name: 'User', foreign_key: 'owner_id', optional: true

  validates_uniqueness_of :mint, scope: :curation_id

  # def associated_curations
  #   Curation.with_submitted_token_mint(self.mint)
  # end
end