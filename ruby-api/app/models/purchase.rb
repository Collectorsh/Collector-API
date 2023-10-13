# frozen_string_literal: true

class Purchase < ApplicationRecord
  belongs_to :user

  serialize :result
end
