# frozen_string_literal: true

class DiscordBid < ApplicationRecord
  belongs_to :discord_notification
  belongs_to :auction
end
