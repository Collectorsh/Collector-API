require 'httparty'

namespace :metadata do
  task mint: :environment do
    mint = "9LChfgJRzkx8P8stiWu39EYoBv8t6BKVvEZTYDN7rmS8"
    mint = Btc::Base58.data_from_base58 mint
    mpid = Btc::Base58.data_from_base58 "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s"
    n = 255
    while n.positive?
      nonce = [n].pack('S').strip
      buf = ['metadata', mpid, mint, nonce, mpid, 'ProgramDerivedAddress'].join
      hex = Digest::SHA256.digest buf
      add = Btc::Base58.base58_from_data hex
      if get_account(add)
        address = add
        break
      end
      n -= 1
    end
    puts address
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
