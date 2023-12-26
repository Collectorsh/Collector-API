class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    # puts "Subscribed to channel notifications_#{params[:socket_id]}"
    stream_from "notifications_#{params[:socket_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end