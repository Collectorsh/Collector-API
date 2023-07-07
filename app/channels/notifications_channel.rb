class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    puts "Subscribed to notifications_channel_#{params[:username]}"
    stream_from "notifications_#{params[:username]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end