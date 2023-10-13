# frozen_string_literal: true

require 'httparty'

namespace :skeletoncrew do
  task magiceden: :environment do
    MagicEden.airdrops
  end
end
