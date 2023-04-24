# frozen_string_literal: true

require 'httparty'
require 'nokogiri'

class MagicEden
  class << self
    def airdrops
      airdrops_array = fetch_from_magiceden
      update_db_records(airdrops_array)
    end

    def fetch_from_magiceden
      skip = 0
      cont = true
      airdrops_array = []
      count = 1
      while cont
        response = HTTParty.get("https://api-mainnet.magiceden.io/rpc/getListedNFTsByQuery?q={\"$match\":{\"collectionSymbol\":\"skeleton_crew_airdrops_and_more\"},\"$sort\":{\"createdAt\":-1},\"$skip\":#{skip},\"$limit\":20}")
        results = JSON.parse(response.body)['results']
        cont = false if results.empty?

        results.each do |result|
          if (drop = airdrops_array.find { |a| a[:name] == result['title'].strip })
            if result['price'] < drop[:floor_price]
              drop[:floor_price] = result['price']
              drop[:floor_mint] = result['mintAddress']
              drop[:order_id] = count
            end
          else
            airdrops_array << { name: result['title'].strip, floor_price: result['price'],
                                floor_mint: result['mintAddress'], order_id: count }
          end
          count += 1
        end
        skip += 20
      end
      airdrops_array
    end

    def update_db_records(airdrops_array)
      Airdrop.all.each do |ad|
        if (result = airdrops_array.detect { |a| a[:name] == ad.name })
          ad.floor_price = result[:floor_price]
          ad.floor_mint = result[:floor_mint]
          ad.order_id = result[:order_id]
        else
          puts ad.name
          ad.floor_price = nil
          ad.floor_mint = nil
          ad.order_id = nil
        end
        ad.save
      end
    end
  end
end
