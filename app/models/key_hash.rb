class KeyHash < ApplicationRecord
  validates :name, allow_nil: false, uniqueness: { case_sensitive: false }
end
