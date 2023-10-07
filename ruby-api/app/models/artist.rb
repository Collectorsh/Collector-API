# frozen_string_literal: true

class Artist < ApplicationRecord
  serialize :tags
  serialize :images
  serialize :public_keys, Array

  has_many :nfts
end
