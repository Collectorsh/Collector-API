module WalletQuery
  Wallet = Holaplex::Client.parse <<-'GRAPHQL'
    query($wallet: PublicKey!) {
      nfts(owners: [$wallet], limit: 20000, offset: 0){
        mintAddress
      }
    }
  GRAPHQL
end
