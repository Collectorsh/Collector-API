# frozen_string_literal: true

class MarketplaceListing < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :artist_name, optional: true
end
