module ListingsQuery
  Listings = Holaplex::Client.parse <<-'GRAPHQL'
    query {
      nfts(auctionHouses: ["3nAR6ZWZQA1uSNcRy3Qya2ihLU9dhaWKfZavoSiRrXzj", "A5CsrtsB6K8DCfFf86jQhpaLSmrYAy38r89JAy73jGGw"], listed: true, limit: 10000, offset: 0){
        name
        image
        mintAddress
        listings {
            price
            seller
            createdAt
            canceledAt
        }
      }
    }
  GRAPHQL
end
