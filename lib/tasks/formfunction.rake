namespace :formfunction do
  task sales: :environment do
    method_wrapper = SolanaRpcRuby::MethodsWrapper.new
    response = method_wrapper.get_signatures_for_address(
      "formn3hJtt8gvVKxpCfzCJGuoz6CNUFcULFZW18iTpC"
    )
    Rails.logger.debug "getting signatures"
    results = response.parsed_response['result']
    Rails.logger.debug "got #{results.length} signatures"
    results.reverse.each do |result|
      method_wrapper = SolanaRpcRuby::MethodsWrapper.new
      transaction = method_wrapper.get_transaction(
        result['signature']
      )
      trans = transaction.parsed_response['result']
      next if trans['meta'] && !trans['meta']['err'].nil?

      log_messages = trans['meta']['logMessages'].join(' ')

      @type = nil

      marketplace = 'formfunction'

      if marketplace == 'exchange'
        if log_messages.include?("Instruction: Buy")
          @type = "buy"
        elsif log_messages.include?("Instruction: TokenList")
          @type = "listing"
          @amount = log_messages.split('price: ')[1].split(')')[0]
        end
      end

      if marketplace == 'formfunction'
        if log_messages.include?("Instruction: Sell") && log_messages.include?("seller_sale_type = InstantSale")
          @type = "listing"
          @amount = nil
        elsif log_messages.include?("buyer_sale_type = InstantSale")
          @type = "buy"
        end
      end

      next unless @type

      puts @type
    end
  end
end
