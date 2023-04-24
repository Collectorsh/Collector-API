# frozen_string_literal: true

class ArtistName < ApplicationRecord
  has_many :followings
  has_many :auctions
  has_many :marketplace_listings
  has_many :marketplace_sales
end
