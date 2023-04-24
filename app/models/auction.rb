# frozen_string_literal: true

class Auction < ApplicationRecord
  has_many :discord_bids
  belongs_to :user, optional: true
  belongs_to :artist_name
end
