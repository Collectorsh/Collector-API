module ApplicationCable
  class Channel < ActionCable::Channel::Base
    rescue_from RuntimeError do |e|
      Rails.logger.error("RuntimeError in Cable channel: #{e.message} - Backtrace: #{e.backtrace.join("\n")}")
    end
  end
end
