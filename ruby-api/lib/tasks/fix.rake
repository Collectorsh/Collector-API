require 'httparty'
require 'json'

namespace :fix do
  task exchange: :environment do
    method_wrapper = SolanaRpcRuby::MethodsWrapper.new
    response = method_wrapper.get_signatures_for_address(
      "5T4oRT1eGjdLNFhcrLWFpVR7TPE3FEG6uWNksAWLvrUb"
    )
    Rails.logger.debug "getting signatures"
    results = response.parsed_response['result']
    Rails.logger.debug "got #{results.length} signatures"
    results.reverse.each do |result|
      GetTransactionFromSignatureJob.perform_now(result['signature'], 'exchange')
    end
  end

  task listings: :environment do
    MarketplaceListing.where(listed: true, source: 'exchange').order(id: :asc).each do |l|
      response = HTTParty.get("https://api.exchange.art/v2/mints/contracts?filters[mints]=#{l.mint}")
      if response.parsed_response["contractGroups"][0]["mint"]["stats"]["numListings"].positive?
        l.update_attribute :amount, response.parsed_response["contractGroups"][0]["mint"]["stats"]["lowestListingPrice"]
      else
        l.update_attribute :listed, false
      end
      puts "updated #{l.id}"
    rescue StandardError => e
      puts e.message
    end
  end

  task ff_listings: :environment do
    MarketplaceListing.where(source: 'formfunction', listed: true).each do |listing|
      method_wrapper = SolanaRpcRuby::MethodsWrapper.new
      transaction = method_wrapper.get_transaction(
        listing.signature
      )
      trans = transaction.parsed_response['result']
      unless trans['transaction']['message']['accountKeys'].include?('3HsusccYUqLfvVfawadnjxQjjAW6GWXYFqpgaKZHvBxw')
        listing.update_attribute :listed, false
      end
    end
  end

  task mints: :environment do
    address = "6fPeCrroRH17Hra7tuztUJ3RUfbDETrrVYSmEyG19S1R"
    user_id = 823
    response = Holaplex::Client.query(WalletQuery::Wallet,
                                      variables: { wallet: address })
    response.data.nfts.each do |nft|
      mint = nft.mint_address
      MintVisibility.where(user_id: user_id, mint_address: mint, visible: true).first_or_create
    end
  end
end
