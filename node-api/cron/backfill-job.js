import cron from "node-cron"
import { backfillIndexer, backfillListings } from "../src/scripts/backfill.js";
import { updateArtistNames } from "../src/scripts/addArtistNames.js";
import { closePostgresConnection } from "../db/postgres.js";

export const runBackfillJob = () => {
  if (process.env.STAGE !== "production") {
    console.log("Not in production, not initializing Backfill Cron Job")
    return
  }
  console.log("Initialize Backfill Cron Job")
  cron.schedule('1 6 * * *', async function() {
    console.log("---------------------")
    console.log("Running Backfill Cron Jobs");
    const r = await backfillListings();
    console.log("Backfill Listing Cron Job Finished:", r);

    const r2 = await backfillIndexer();
    console.log("Backfill Indexer Cron Job Finished:", r2);

    const r3 = await updateArtistNames();
    console.log("Update Artist Names Cron Job Finished:", r3);
  });
}