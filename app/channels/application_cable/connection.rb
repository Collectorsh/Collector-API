module ApplicationCable
  class Connection < ActionCable::Connection::Base
  end
  def report_error(e)
    puts "Action Cable Error: #{e.message}"
  end
end
