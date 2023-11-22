import cron from "node-cron"
import { backfill } from "../src/scripts/backfill.js";

export const runBackfillJob = () => {
  if (process.env.STAGE !== "production") {
    console.log("Not in production, not initializing Backfill Cron Job")
    return
  }
  console.log("Initialize Backfill Cron Job")
  cron.schedule('1 6 * * *', async function() {
    console.log("---------------------")
    console.log("Running Backfill Cron Job");
    const r = await backfill();
    console.log("Backfill Cron Job Finished:", r);
  });
}