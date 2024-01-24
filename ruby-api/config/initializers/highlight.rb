require "highlight"

Highlight::H.new("neykmqvg", environment: "production") do |c|
  c.service_name = "collector-rails-app"
  # c.service_version = "git-sha"
  c.service_version = "1.0.0"
end

# you can replace the Rails.logger with Highlight's
# Rails.logger = Highlight::Logger.new(STDOUT)

# # or alternatively extend it to log with both
highlightLogger = Highlight::Logger.new(nil)
Rails.logger.extend(ActiveSupport::Logger.broadcast(highlightLogger))
