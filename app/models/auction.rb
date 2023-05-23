# frozen_string_literal: true

class Auction < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :artist_name
end
