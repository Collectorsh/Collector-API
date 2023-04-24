# frozen_string_literal: true

class Metadata < ApplicationRecord
  serialize :meta_attributes, Array
  serialize :creators, Array

  validates :uri, uniqueness: true
end
