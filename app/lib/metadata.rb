require 'httparty'

module Metadata
  def self.extract(data)
    metadata = {}
    metadata[:creators] = []
    metadata[:verified] = []
    metadata[:share] = []

    data = Base64.decode64(data)

    metadata[:update_authority] = Btc::Base58.base58_from_data(data[1..32].unpack('H*').pack('H*'))
    metadata[:mint] = Btc::Base58.base58_from_data(data[33..64].unpack('H*').pack('H*'))
    name_len = data[65..68].unpack1('I*')
    i = 69 + name_len - 1
    metadata[:name] =
      data[69..i].unpack('H*').pack('H*').strip.encode!("UTF-8", invalid: :replace,
                                                                 undef: :replace).force_encoding("utf-8")
    i += 1
    symbol_len = data[i..i + 3].unpack1('I*')
    i += 4
    metadata[:symbol] =
      data[i..i + symbol_len - 1].unpack('H*').pack('H*').strip.gsub('"', '').encode!("UTF-8", invalid: :replace,
                                                                                               undef: :replace).force_encoding("utf-8")
    i += symbol_len
    uri_len = data[i..i + 3].unpack1('I*')
    i += 4
    metadata[:uri] =
      data[i..i + uri_len - 1].unpack('H*').pack('H*').strip.encode!("UTF-8", invalid: :replace,
                                                                              undef: :replace).force_encoding("utf-8")
    i += uri_len
    metadata[:seller_fee_basis_points] = data[i..i + 1].unpack1('S_')
    i += 2
    has_creator = data[i]&.ord
    i += 1
    if has_creator == 1
      creator_len = data[i..i + 3].unpack1('I*')
      i += 4
      (1..creator_len).each do |_|
        unless data[i..i + 31].nil?
          metadata[:creators] << Btc::Base58.base58_from_data(data[i..i + 31].unpack('H*').pack('H*'))
        end
        i += 32
        metadata[:verified] << data[i]&.ord
        i += 1
        metadata[:share] << data[i]&.ord
        i += 1
      end
    end
    metadata[:primary_sale_happened] = data[i]&.ord
    i += 1
    metadata[:is_mutable] = data[i]&.ord
    metadata
  end

  def self.find_pda(mint)
    resp = HTTParty.post("#{ENV['COLLECTOR_API']}/pda_from_mint", body: { mint: mint }.to_json,
                                                                  headers: { 'Content-Type' => 'application/json' })
    add = resp['pda']
    result = get_account(add)
    extract(result['data'][0]) unless result.nil?
  end

  def self.get_account(account)
    method_wrapper = SolanaRpcRuby::MethodsWrapper.new
    response = method_wrapper.get_account_info(
      account,
      encoding: 'jsonParsed'
    )
    results = response.parsed_response['result']
    results['value']
  end
end
