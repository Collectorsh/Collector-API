# frozen_string_literal: true

class Following < ApplicationRecord
  belongs_to :user
  belongs_to :artist_name
end
