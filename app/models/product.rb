# frozen_string_literal: true

class Product < ApplicationRecord
  belongs_to :product_collection

  serialize :sizes, Array
  serialize :images, Array
end
