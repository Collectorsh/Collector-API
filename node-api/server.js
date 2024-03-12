import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import dotenv from 'dotenv';
import multer from 'multer';
import { uploadMetadata } from './src/controllers/uploadMetadata.js';
import { uploadCollectionMetadata } from './src/controllers/uploadCollectionMetadata.js';
import { runBackfillJob } from './cron/backfill-job.js';
import { backfillIndexer, backfillListings, updateIndexerEditions } from './src/scripts/backfill.js';
import { logtail } from './src/utils/logtail.js';
import { updateArtistNames } from './src/scripts/addArtistNames.js';
import { closePostgresConnection } from './db/postgres.js';



dotenv.config();

const uploadMiddleware = multer({
  dest: 'uploads/',
  limits: { fileSize: 124 * 1024 * 1024 }  // 124 MB
});

const app = express();
const PORT = process.env.NODE_PORT || 3002;

app.use(helmet());
app.use(express.json());

function setNoTimeout(req, res, next) {
  req.setTimeout(0);  // Set no timeout
  next();
}

const origin = () => {
  if (process.env.NODE_ENV === 'dev') {
    return 'http://localhost:3000';
  }
  return ["https://collector.sh/", "https://collector-testing-kvak9.ondigitalocean.app/"];
}
app.use(cors({
  origin: origin(),
}))

app.get('/', (req, res) => {
  res.send('Hello, World!');
});

app.post('/upload-metadata',
  setNoTimeout,
  uploadMiddleware.fields([{ name: 'imageFile', maxCount: 1 }, { name: 'altMediaFile', maxCount: 1 }]),
  uploadMetadata
)

app.post('/upload-collection-metadata',
  setNoTimeout,
  uploadMiddleware.fields([{ name: 'imageFile', maxCount: 1 }]),
  uploadCollectionMetadata
)

app.get('/runBackfillJob', async (req, res) => {
  const backfillListingsResponse = await backfillListings();
  // const backfillIndexerResponse = await backfillIndexer()
  res.send({ 
    backfillListingsResponse,
    // backfillIndexerResponse
   });
})

app.get('/updateArtistNames', async (req, res) => { 
  const response = await updateArtistNames()
  res.send(response);
})

app.get('/updateIndexer', async (req, res) => {
  const response = await updateIndexerEditions()
  res.send(response);
})

app.get('/health', (req, res) => { res.send("OK!") })

//initiate cron job for backfills
runBackfillJob();

//handle errors
process.on('SIGINT', async () => {
  console.log('Received SIGINT. Shutting down gracefully.');
  await logtail.flush();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('Received SIGTERM. Shutting down gracefully.');
  await logtail.flush();
  process.exit(0);
});

process.on('uncaughtException', async (error) => {
  console.error('Uncaught Exception:', error);
  logtail.error(`Uncaught Exception: ${error.message}`);
  await logtail.flush()
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  logtail.error(`Unhandled Rejection at: ${promise}, reason: ${reason}`);
});

//Start server
logtail.info('Starting server');
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${ PORT }`);
});
