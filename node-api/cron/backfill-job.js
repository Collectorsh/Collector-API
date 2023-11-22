import cron from "node-cron"
import { backfill } from "../src/scripts/backfill.js";

export const runBackfillJob = () => {
  console.log("init cron")
  cron.schedule('1 6 * * *', async function() {
    console.log("---------------------")
    console.log("Running Backfill Cron Job");
    const r = await backfill();
    console.log("Backfill Cron Job Finished:", r);
  });
}