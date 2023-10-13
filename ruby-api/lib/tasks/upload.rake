# frozen_string_literal: true

require 'aws-sdk-s3'
require 'down'
require 'httparty'
require 'csv'

namespace :upload do
  task airdrops: :environment do
    file = CSV.read('./unknown_artist.csv', liberal_parsing: true)
    file.each do |row|
      airdrop = SkeletoncrewAirdrop.find_by_name(row[0])
      airdrop.artist = row[1]
      airdrop.save
    end
  end

  task image: :environment do
    url = "https://arweave.net/tWWd1b1mj-9GZ8o2HhHo-iKb0CQkYfu4nvbRcnvC-QQ?ext=png"
    mint = "CdyqvkoSQtrzaGxa7KbRJ942vJxkKuuFLvLQUYFeziKp"
    UploadImageJob.perform_now(url, mint)
  end

  def client
    Aws::S3::Client.new(
      access_key_id: 'R2BCBXAYDQPKCG4DHNSV',
      secret_access_key: 'W6QH+NNjcUwcMAm0n/YEWQZ9OzkBjuyFANeMc+p60Bo',
      endpoint: 'https://sfo3.digitaloceanspaces.com',
      region: 'us-east-1'
    )
  end

  def remoteFileExist(url)
    urlParsed = URI(url)
    response = nil
    Net::HTTP.start(urlParsed.host, 80) do |http|
      response = http.head(urlParsed.path.to_s + urlParsed.query.to_s)
    end

    if response.code[0, 1] == "2" || response.code[0, 1] == "3"
      true
    else
      false
    end
  end
end
