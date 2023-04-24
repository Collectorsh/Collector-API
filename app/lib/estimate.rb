module Estimate
  def self.check_exchange(mint)
    sales = []

    response = HTTParty.get("https://api.exchange.art/v2/mints/contracts?filters[mints]=#{mint}")
    return unless response.parsed_response["contractGroups"]
    return unless response.parsed_response["contractGroups"][0]
    return unless response.parsed_response["contractGroups"][0]["mint"]

    is_master_edition = response.parsed_response["contractGroups"][0]["mint"]["isMasterEdition"]

    collection = response.parsed_response["contractGroups"][0]['mint']['collection']['name']
    collection = collection.encode("ASCII", "UTF-8", undef: :replace)
    response = HTTParty.get("https://api.exchange.art/v2/mints/contracts?from=0&filters[collections]=#{collection}&limit=1000")

    response.parsed_response['contractGroups'].each do |group|
      next unless group['mint']['isMasterEdition'] == is_master_edition
      next unless group['mint']['stats']
      next unless group['mint']['stats']['lastSalePrice']

      sales << group['mint']['stats']['lastSalePrice']
    end
    return if sales.empty?

    average = sales.sum / sales.length if sales.length.positive?

    listings = 0
    floor = 999_999_999_999_999_999
    response.parsed_response['contractGroups'].each do |group|
      next unless group['mint']['isMasterEdition'] == is_master_edition

      listings += group['availableContracts']['listings'].length
      group['availableContracts']['listings'].each do |l|
        amount = l['data']['listingAmount']
        floor = amount if amount < floor
      end
    end

    return average if floor == 999_999_999_999_999_999
    return floor if average.nil?

    listings > 5 ? floor : average + ((floor - average) / 2)
  rescue StandardError => e
    Bugsnag.notify(e)
  end

  def self.check_db(mint)
    metadata = Metadata.find_pda(mint)
    creator = metadata[:creators][0]

    artist = ArtistName.find_by(public_key: creator)
    return unless artist

    sales = 0
    total = 0

    # check if it's an edition
    master_edition = Auction.find_by(mint: mint)

    if master_edition
      auctions = Auction.where(artist_name_id: artist.id, finalized: true)

      sales += auctions.count
      total += auctions.sum(:highest_bid)
    else
      msales = MarketplaceSale.where(transaction_type: 'edition', artist_name_id: artist.id)

      sales += msales.count
      total += msales.sum(:amount)
    end
    return unless total.positive?

    total / sales
  rescue StandardError => e
    Bugsnag.notify(e)
  end

  def self.check_magic_eden(mint)
    response = HTTParty.get("https://api-mainnet.magiceden.dev/v2/tokens/#{mint}")
    collection = response.parsed_response['collection']
    response = HTTParty.get("https://api-mainnet.magiceden.dev/v2/collections/#{collection}/stats")
    response.parsed_response['floorPrice']
  rescue StandardError => e
    Bugsnag.notify(e)
  end

  def self.find_artist_from_mint(mint)
    if (auction = Auction.find_by(mint: mint))
      return auction.brand_name
    end

    if (listing = MarketplaceListing.find_by(mint: mint))
      return listing.artist_name
    end

    return unless (sale = MarketplaceSale.find_by(mint: mint))

    sale.artist_name
  end
end
