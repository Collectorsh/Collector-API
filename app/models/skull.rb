# frozen_string_literal: true

class Skull < ApplicationRecord
  serialize :meta_attributes, Array
  serialize :collection, Hash
  serialize :properties, Hash
  serialize :creators, Array
  serialize :verified, Array
  serialize :share, Array
end
