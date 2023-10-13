# frozen_string_literal: true

class SendOrderEmailJob < ApplicationJob
  queue_as :order

  def perform(purchase)
    message = "Order Number: #{purchase.order_number}\n\n"
    JSON.parse(purchase.address.gsub('=>', ':')).each do |a|
      message += "#{a[0]}: #{a[1]}\n"
    end
    message += "\n"
    JSON.parse(purchase.order).each do |o|
      message += "Quantity: #{o['qty']}\n"
      message += "Size: #{o['size']}\n"
      message += "Name: #{o['product']['name']}\n"
      message += "Description: #{o['product']['description']}\n"
    end
    message_params = {
      from: 'notify@collector.sh',
      to: 'richardfsr@gmail.com',
      subject: "Collector Order #{purchase.order_number}",
      text: message
    }
    # send message
  end
end
