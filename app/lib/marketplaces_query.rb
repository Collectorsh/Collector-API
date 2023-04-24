module MarketplacesQuery
  Marketplaces = Holaplex::Client.parse <<-'GRAPHQL'
    query {
      marketplaces(limit: 1000) {
        subdomain
        auctionHouses {
          address
        }
      }
    }
  GRAPHQL
end
