import axios from "axios";
import postgres from "../../db/postgres.js";
import { logtail } from "../utils/logtail.js";
import { parseError, pause } from "../utils/misc.js";

const SOURCES = {
  COLLECTOR: "collector",
  MALLOW: "mallow",
  NOT_IN_MALLOW: "not_in_mallow"
}

export const updateArtistNames = async () => {
  console.log("-------------------")
  console.log("Running Update Artist Names Script")
  //get artist_addresses from all mintedIndex items
  try {
    const indexes = await postgres('minted_indexer')
      .select("artist_address", "artist_id")
      .whereNot('nft_state', 'burned')
    
    const artistNames = await postgres('artist_names')
      .select("*")
      .whereNotNull("artist_id")
      .orWhere("source", SOURCES.MALLOW)
      .orWhere("source", SOURCES.NOT_IN_MALLOW) //addresses that are confirmed not in mallow
    

    const artistNamesMap = artistNames.reduce((acc, curr) => { 
      if (curr.artist_id) {
        acc.withID[curr.public_key] = curr
      } else {
        acc.other[curr.public_key] = curr
      }
      return acc;
    }, {
      withID: {},
      other: {}
    })

    const artistNameItems = []
  
    //start with objects to dedup
    let withArtistIdsToAdd = {}
    let sansIdArtistsToAdd = {}

    indexes.forEach(index => {
      //index items with an artist_id
      const hasId = Boolean(index.artist_id)

      //artist_address not already in the artistNames table with id
      const inDb = Boolean(artistNamesMap.withID[index.artist_address])

      if (hasId && !inDb) withArtistIdsToAdd[index.artist_address] = index
      if (!inDb) sansIdArtistsToAdd[index.artist_address] = index
    })

    //deduping
    withArtistIdsToAdd = Object.values(withArtistIdsToAdd)
    sansIdArtistsToAdd = Object.values(sansIdArtistsToAdd)
    
    const withIdMunged = withArtistIdsToAdd.map(index => ({
      artist_id: index.artist_id,
      public_key: index.artist_address,
      source: SOURCES.COLLECTOR
    }))
    artistNameItems.push(...withIdMunged)
    
    // take sansIdArtistsToAdd and see if you can find collector user ids
    // if so add with user id
    for (const index of sansIdArtistsToAdd) { 
      
      //get id from collector users
      const collectorArtistID = await postgres('users')
      .select('id')
      .whereLike('public_keys', `%${ index.artist_address }%`)
      .first()
      .then(r => r?.id)
      .catch(e => { 
        console.log("Error getting collector user id: ", e)
      })
      
      if (collectorArtistID) {
        //add to artistNameItems with id and collector source
        artistNameItems.push({
          artist_id: collectorArtistID,
          public_key: index.artist_address,
          source: SOURCES.COLLECTOR
        })
      } else {
        // if already in db from mallow continue
        const inDb = Boolean(artistNamesMap.other[index.artist_address])
        if (inDb) continue;
        
        //else find username from mallow
        // if found add to artistNameItems with mallow source and username
        await pause() //pause to avoid rate limiting
        const mallowName = await fetchMallowName(index.artist_address)
        if (mallowName) { 
          artistNameItems.push({
            public_key: index.artist_address,
            source: SOURCES.MALLOW,
            name: mallowName
          })
        } else {
          artistNameItems.push({
            public_key: index.artist_address,
            source: SOURCES.NOT_IN_MALLOW,
          })
        }
        
      }  
    }
    
    if (!artistNameItems.length) {
      console.log("No artists to add")
      return {updated: [], state: "no artists to add"}
    }
    
    const now = new Date()
    const updated = await postgres('artist_names')
      .insert(artistNameItems.map(a => ({
        ...a,
        created_at: now,
        updated_at: now
      })))
      .onConflict(['artist_id', 'public_key'])
      .ignore()
      .returning("*");
    
    return { updated, state: "success"}
  } catch (e) {
    const err = parseError(e)
    console.log("Error adding artist names: ", err)
    logtail.error(`Add Artist Name error: ${ err}`)
  }
  console.log("DONE")
}

async function fetchMallowName(artistAddress) {
  const url = `https://api.mallow.art/users/${ artistAddress }`;
  const headers = {
    "X-Api-Key": process.env.MALLOW_API_KEY,
  };
  try {
    const response = await axios.get(url, { headers: headers });

    const result = response.data.result
    const displayName = result.displayName;
    const username = result.username;

    const name = displayName || username
    return name
  } catch (error) {
    const message = error.message;
    if (!message.includes("404")) console.error("Error fetching Mallow Name:", message);
  }
}