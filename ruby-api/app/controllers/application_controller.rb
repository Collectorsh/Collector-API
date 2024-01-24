# frozen_string_literal: true
require "highlight"

class ApplicationController < ActionController::API
  include Highlight::Integrations::Rails

  around_action :with_highlight_context
end
