# frozen_string_literal: true

class Watchlist < ApplicationRecord
  has_many :watchlist_bids
end
