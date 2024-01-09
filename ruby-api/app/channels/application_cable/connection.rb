module ApplicationCable
  class Connection < ActionCable::Connection::Base
  end
  def report_error(e)
    puts "Action Cable Error: #{e.message}"
    Rails.logger.error("Action Cable Error: #{e.message} - Backtrace: #{e.backtrace.join("$/")}")
  end

  rescue RuntimeError => e
    Rails.logger.error("RuntimeError in Cable application: #{e.message} - Backtrace: #{e.backtrace.join("$/")}")
  end
end
