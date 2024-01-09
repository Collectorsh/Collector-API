class NotificationsChannel < ApplicationCable::Channel
  rescue_from RuntimeError do |e|
    log_error("RuntimeError", e)
  end

  def subscribed
    # puts "Subscribed to channel notifications_#{params[:socket_id]}"
    stream_from "notifications_#{params[:socket_id]}"
  rescue StandardError => e
    log_error("StandardError-subscribed", e)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  rescue StandardError => e
    log_error("StandardError-unsubscribed", e)
  end

  private

  def log_error(error_type, e)
    Rails.logger.error("#{error_type} in Cable notifications: #{e.message} - Backtrace: #{e.backtrace.join("\n")}")
  end
end