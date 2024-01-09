module ApplicationCable
  class Connection < ActionCable::Connection::Base
    rescue_from RuntimeError do |e|
      log_error("RuntimeError", e)
    end
  end

  
  def report_error(e)
    Rails.logger.error("Action Cable Error: #{e.message} - Backtrace: #{e.backtrace.join("$/")}")
  end

  private

  def log_error(error_type, e)
    Rails.logger.error("#{error_type} in Cable connection: #{e.message} - Backtrace: #{e.backtrace.join("\n")}")
  end
end
