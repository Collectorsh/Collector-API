# frozen_string_literal: true

class DiscordNotification < ApplicationRecord
  has_many :discord_bids

  serialize :artists, Array
  serialize :creator, Array
end
