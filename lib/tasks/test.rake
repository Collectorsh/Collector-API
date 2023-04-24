namespace :test do
  task cdn: :environment do
    UploadImageJob.perform_later 'https://bafybeif6dakkacjbtksetafqti3bywebpeqkxiu3rnlhwitb5qtf74hljm.ipfs.dweb.link?ext=png',
                                 'BMQCLokEU4bYAoNwuywuibTqJiSmwKfeSpNRRvfrqeXy'
  end

  task listing_estimate: :environment do
    UpdateListingEstimatesJob.perform_now
  end

  task ff: :environment do
    response = Formfunction::Client.query(UserQuery::User, variables: { username: "aligulec" })
    puts response.data.user[0].twitter_name.inspect
  end

  task hola: :environment do
    response = Holaplex::Client.query(ListingsQuery::Listings)
    listings = response.data.listings
    # active = listings.select { |l| l.ended == false && !l.ends_at.nil? }
    # puts active.inspect
    # puts "-------count-------"
    # puts active.count
  end

  task activities: :environment do
    UpdateCollectorActivitiesJob.perform_now
  end

  task tokens: :environment do
    account = '2eBBNzw7DeWuYfWhPVGanm7VyYogiWKjSRcAHhcDFSMd'
    method_wrapper = SolanaRpcRuby::MethodsWrapper.new
    response = method_wrapper.get_token_accounts_by_owner(
      account,
      program_id: 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA',
      encoding: 'jsonParsed'
    )
    results = response.parsed_response['result']
    tokens = []
    results['value'].each do |value|
      token = value['account']['data']['parsed']['info']
      tokens << token['mint'] if token['tokenAmount']['decimals'].zero?
    end

    response = method_wrapper.get_multiple_accounts(
      tokens,
      encoding: 'base64'
    )
    results = response.parsed_response['result']
    raise results['value'][1].inspect
  end
end
