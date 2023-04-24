module MintQuery
  Mint = Holaplex::Client.parse <<-'GRAPHQL'
    query($mint: String!) {
      nft(address: $mint) {
        name
        creators {
          address
        }
      }
    }
  GRAPHQL
end
