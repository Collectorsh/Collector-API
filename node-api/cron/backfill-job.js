import cron from "node-cron"
import { backfill } from "../src/scripts/backfill.js";

export const runBackfillJob = () => {
  console.log("init cron")
  cron.schedule('30 13 * * *', function() {
    console.log("---------------------")
    console.log("Running Backfill Cron Job");
    backfill();
  });
}