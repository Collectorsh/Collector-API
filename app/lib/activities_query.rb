module ActivitiesQuery
  Activities = Holaplex::Client.parse <<-'GRAPHQL'
    query($auctionHouses: [PublicKey!]!) {
      activities(auctionHouses:  $auctionHouses) {
        activityType
        createdAt
        price
        metadata
        wallets {
          address
        }
        nft {
          name
          address
          mintAddress
        }
        auctionHouse {
          address
        }
      }
    }
  GRAPHQL
end
