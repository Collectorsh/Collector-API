# frozen_string_literal: true

class UserFollowing < ApplicationRecord
  belongs_to :user
end
