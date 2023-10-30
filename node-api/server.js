import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import dotenv from 'dotenv';
import multer from 'multer';
import { uploadMetadata } from './src/controllers/uploadMetadata.js';
import { uploadCollectionMetadata } from './src/controllers/uploadCollectionMetadata.js';
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

app.get('/health', (req, res) => { res.send("OK!")})

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${ PORT }`);
});