require 'httparty'

namespace :artist do
  task names: :environment do
    artists = Auction.all.select(:brand_name, :collection_name, :source, :end_time)
                     .group(:brand_name, :collection_name, :source, :end_time)
                     .order(end_time: :asc)
    artists.each do |artist|
      next if ArtistName.where(name: artist.brand_name, source: artist.source).first

      mint = Auction.where(brand_name: artist.brand_name, collection_name: artist.collection_name, source: artist.source).last.mint
      puts mint
      mint = Btc::Base58.data_from_base58 mint
      mpid = Btc::Base58.data_from_base58 "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s"
      n = 255
      while n.positive?
        nonce = [n].pack('S').strip
        buf = ['metadata', mpid, mint, nonce, mpid, 'ProgramDerivedAddress'].join
        hex = Digest::SHA256.digest buf
        add = Btc::Base58.base58_from_data hex
        if (result = get_account(add))
          metadata = Metadata.extract(result['data'][0])
          creator = metadata[:creators][0]
          break
        end
        n -= 1
      end
      ArtistName.where(public_key: creator, name: artist.brand_name, collection: artist.collection_name, source: artist.source).first_or_create
    end
  end

  task twitter: :environment do
    ArtistName.where("twitter IS NULL").each do |artist|
      twitter = get_artist_twitter_exchange(artist.collection) if artist.source == 'exchange'
      twitter = get_artist_twitter_formfunction(artist.name) if artist.source == 'formfunction'
      twitter = get_artist_twitter_holaplex(artist.public_key) if artist.source == 'holaplex'

      artist.update_attribute(:twitter, twitter) if twitter
    end
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

def get_artist_twitter_exchange(collection_name)
  response = HTTParty.get("https://api.exchange.art/v1/public/collections/metadata?collectionName=#{collection_name}")

  twitter = response.parsed_response['states']['live']['twitter'].split('/').last
  puts twitter
  "@#{twitter.strip}"
rescue StandardError => e
  Rails.logger.error e.message
  nil
end

def get_artist_twitter_formfunction(username)
  response = Formfunction::Client.query(UserQuery::User, variables: { username: username })

  twitter = response.data.user[0].twitter_name
  puts twitter
  "@#{twitter.strip}"
rescue StandardError => e
  Rails.logger.error e.message
  nil
end

def get_artist_twitter_holaplex(address)
  response = Holaplex::Client.query(CreatorQuery::Creator, variables: { address: address })

  twitter = response.data.creator.profile.handle
  puts twitter
  "@#{twitter.strip}"
rescue StandardError => e
  Rails.logger.error e.message
  nil
end
