# frozen_string_literal: true

class MarketplaceSale < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :artist_name, optional: true
end
