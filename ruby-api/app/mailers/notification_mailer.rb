# frozen_string_literal: true

class NotificationMailer < ApplicationMailer
  def notify(c, s, floor, msg)
    @msg = msg
    @name = s.name
    @price = s.price
    @rank = s.rank
    @img = s.img
    @floor = floor
    @previous = s.previous_price
    @url = "https://howrare.is#{s.link}"
    mail(to: %w[richardfsr@gmail.com], subject: "Snipe Opportunity: #{c.name}", from: 'looksrare.so@gmail.com')
  end
end
