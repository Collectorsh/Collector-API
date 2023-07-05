class NotificationsChannel < ApplicationCable::Channel
  def subscribed
     stream_from "notifications_channel_#{params[:username]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end