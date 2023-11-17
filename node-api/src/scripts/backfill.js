export const backfill = async () => { 
  //fetch all curation_listings

  //find onchain owner address,

  // check if token has been burned if so delete

  //if it doesnt match the current owner...
    //if master edition with supply over 0...
      //make sure this is connected to a master edition market transaction
      // update listed_status to "listed"
      //find master_edition_market_address and update
      //find price and update "buy_now_price"
  
    // else if 1/1 or edition ...
      //update "owner_address"
      //find new collector user /owner id from that address, update "owner_id" as well (or set to null if not a collector user)
      //update "listed_status" to unlisted
      //remove listing_receipt
      //change "primary_sale_happened" to true
  
      //(if there is an easy way to check sales transactions, instead of "unlisted" can mark as sold or "unknown" if its not easy to verify)
  //end
  
  //check if uri has been changed, if so update all metadata to match (name, aspect_ratio, image, description, animation_url, creators, files)
  

  //same process with minted_indexer
  console.log("LOGGGING", new Date().toLocaleDateString())
  console.log("L time", new Date().toLocaleTimeString())
}