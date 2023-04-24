# frozen_string_literal: true

class TokenMint < ApplicationRecord
  belongs_to :user, optional: true
end
