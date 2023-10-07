class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
  def get_artist_twitter_exchange(collection_name)
    response = HTTParty.get("https://api.exchange.art/v1/public/collections/metadata?collectionName=#{collection_name}")

    twitter = response.parsed_response['states']['live']['twitter'].split('/').last

    "@#{twitter.strip}"
  rescue StandardError => e
    Rails.logger.error e.message
    nil
  end

  def marketplace_link(auction)
    case auction.source
    when 'exchange'
      "https://exchange.art/single/#{auction.mint}"
    when 'formfunction'
      "https://formfunction.xyz/@/#{auction.mint}"
    when 'holaplex'
      "https://www.holaplex.com/nfts/#{auction.mint}"
    when 'collector'
      "https://collector.sh/nft/#{auction.mint}"
    end
  end

  def get_account(account)
    method_wrapper = SolanaRpcRuby::MethodsWrapper.new
    response = method_wrapper.get_account_info(
      account,
      encoding: 'jsonParsed'
    )
    results = response.parsed_response['result']
    results['value']
  end
end
