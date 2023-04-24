# frozen_string_literal: true

class WatchlistBid < ApplicationRecord
  belongs_to :watchlist
  belongs_to :auction
end
