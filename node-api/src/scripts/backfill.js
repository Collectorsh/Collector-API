import { PublicKey } from "@solana/web3.js"
import postgres from "../../db/postgres.js"
import { connection } from "../utils/RpcConnection.js"
import { Metaplex } from "@metaplex-foundation/js"
import { verifyTokenBurned } from "./verifyTokenBurned.js"

export const backfill = async () => { 
  console.log("-------------------")
  console.log("Running Backfill Script")
  //fetch all curation_listings
  const active_listings = await postgres('curation_listings')
    .where({
      listed_status: 'listed',
    })
    .catch((e) => {
      console.log("Error fetching curation listings", e)
    })
  
  //find onchain owner address,
  const metaplex = Metaplex.make(connection);
  const results = await Promise.all(active_listings.map(async (listing) => { 
    let res = {mint: listing.mint}
    const mintPublicKey = new PublicKey(listing.mint);

    //fetch metadata account
    //if metadata account doesn't exist, verify token has been burned
    let metadataAccountInfo = null;
    try {
      const largestAccounts = await connection.getTokenLargestAccounts(mintPublicKey);
      metadataAccountInfo = await connection.getParsedAccountInfo(largestAccounts.value[0].address);

      
    } catch (e) {
      const state = await verifyTokenBurned(mintPublicKey)
      // update curation_listing "nft_state" based on burn verification
      const update = await postgres('curation_listings')
        .update({ nft_state: state, listed_status: "unlisted" })
        .where({ mint: listing.mint })
        .catch((e) => { 
          console.log(`Error updating curation_listing ${list.mint}  burn state:`, e)
        })
      res.update = update;
      res.state = state;
    }
      
    try {      
      if (!metadataAccountInfo) return res;      

      //looking out for owner mismatches, which invalidates listings (unless its a master edition)
      const owner = metadataAccountInfo.value.data.parsed.info.owner
      if (owner !== listing.owner_address) {
        res.ownersMatch = false;
        const metadata = await metaplex.nfts().findByMint({
          mintAddress: mintPublicKey
        })

        const editionData = metadata.edition;
      
        const isMasterEdition = Number(editionData.maxSupply) > 0;

        res.isMasterEdition = isMasterEdition;
        if (isMasterEdition) {
          res.edition_address = listing.master_edition_market_address;
          //owner will change when listing, just make sure we have recorded the master edition market address
          //if not flag it (eventually automate this process)
          if (!listing.master_edition_market_address) {

            //TEMPORARY FLAG PROCESS

            // update curation_listing "nft_state" to flag missing market address
            const state = "edition-market-address-missing"
            const update = await postgres('curation_listings')
              .update({
                nft_state: state,
              })
              .where({ mint: listing.mint })
              .catch((e) => {
                console.log(`Error updating curation_listing ${ listing.mint }  burn state:`, e)
              })
            res.update = update;
            res.state = state

            //EVENTUALLY IMPLEMENT THIS AUTOMATED PROCESS

            //TODO make sure this is connected to a master edition market transaction
            //Parsing transactions
            // const transactionSignatures = await connection.getSignaturesForAddress(mintPublicKey);
            // res.transactions = [];
            // for (const signatureInfo of transactionSignatures) {
            //   console.log("Transaction Signature:", signatureInfo.signature);
  
            //   try {
            //     const transactionDetails = await connection.getTransaction(signatureInfo.signature, {
            //       commitment: "finalized",
            //       maxSupportedTransactionVersion: 1
            //     });
            //     res.transactions.push(transactionDetails)
  
            //   } catch (e) {
            //     console.log("Error fetching transaction details", e)
            //   }
            // }
  
            //get the market edition address from the transactions and update master_edition_market_address
            //fetch market edition data, get listing price and update "buy_now_price"     
            // update listed_status to "listed"
          }
        } else {
          const state = "invalid-listing"
          res.state = state
          res.owner = owner;
          res.prev_owner = listing.owner_address;

          //try to find the owners Collector user id if it exists
          const ownerId = await postgres('users')
            .select('id')
            .whereLike('public_keys', `%${owner}%`)
            .first()

          res.ownerId = ownerId;

          const update = await postgres('curation_listings')
            .update({
              nft_state: state,
              owner_address: owner,
              owner_id: ownerId ? ownerId.id : null,
              listed_status: "unlisted",
            })
            .where({ mint: listing.mint })
            .catch((e) => {
              console.log(`Error updating curation_listing ${ listing.mint }  burn state:`, e)
            })
          res.update = update;
        }
       

      } else {
        //Another invalid listing could be if the token is frozen

        // default is "initialized", looking out for "frozen"
        // if was frozen or is frozen and it doesnt match the current db state update curation_listing "nft_state" to match current
        const state = metadataAccountInfo.value.data.parsed.info.state;
        const wasOrIsFrozen = state === "frozen" || listing.nft_state === "frozen"
        //listing.nft_state is "frozen" if it was frozen before, if its been changed we need to revert teh db to match the onchain state
        if (wasOrIsFrozen && state !== listing.nft_state) {
          //update curation_listing "nft_state" 
          const update = await postgres('curation_listings')
            .update({ nft_state: state })
            .where({ mint: listing.mint })
            .catch((e) => {
              console.log(`Error curation_listing ${ listing.mint } nft state:`, e)
            })
          res.update = update;
          res.state = state;
        }
      }
      
    } catch (e) {
      res.error = `Error fetching metadata ${ listing.mint }: ${e}`
    }
    return res
  }))

  return results.filter(res => {
    return res.state && res.state !== "initialized"
  })

  // TODO same process with minted_indexer
}


