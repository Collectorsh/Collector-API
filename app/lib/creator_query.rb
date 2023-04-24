module CreatorQuery
  Creator = Holaplex::Client.parse <<-'GRAPHQL'
    query($address: String!) {
      creator(address: $address) {
        profile {
          handle
        }
      }
    }
  GRAPHQL
end
