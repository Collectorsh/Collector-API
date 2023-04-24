# frozen_string_literal: true

require 'httparty'
require 'json'

class UpdateExchangeOffersJob < ApplicationJob
  queue_as :exchange

  def perform
    # sig = MarketplaceSale.where("source = 'exchange' AND transaction_type = 'offer' AND signature IS NOT NULL")
    #                      .order(id: :desc).limit(1)
    # @last_signature = sig.last ? sig.last.signature : ""

    method_wrapper = SolanaRpcRuby::MethodsWrapper.new
    response = method_wrapper.get_signatures_for_address(
      "exofLDXJoFji4Qyf9jSAH59J4pp82UT5pmGgR6iT24Z"
    )
    Rails.logger.debug "getting signatures"
    results = response.parsed_response['result']
    Rails.logger.debug "got #{results.length} signatures"
    results.reverse.each do |result|
      unless result['blockTime'] < (Time.now - 1.hour).to_i
        GetTransactionFromSignatureJob.perform_later(result['signature'],
                                                     'exchange')
      end
    end
  rescue StandardError => e
    Rails.logger.error e.message
    Bugsnag.notify(e)
  end
end
