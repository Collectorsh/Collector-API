module ApplicationCable
  class Connection < ActionCable::Connection::Base
    rescue_from RuntimeError do |e|
      Rails.logger.error("Runtime in Cable connection: #{e.message} - Backtrace: #{e.backtrace.join("\n")}")
    end
  end

  
  def report_error(e)
    Rails.logger.error("Action Cable Error: #{e.message} - Backtrace: #{e.backtrace.join("$/")}")
  end
end
