# frozen_string_literal: true

class Bid < ApplicationRecord
  belongs_to :user
  belongs_to :auction
end
