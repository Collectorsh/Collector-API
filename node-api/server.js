import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import dotenv from 'dotenv';
import multer from 'multer';
import { uploadMetadata } from './src/controllers/uploadMetadata.js';
dotenv.config();

const uploadMiddleware = multer({
  dest: 'uploads/',
  limits: { fileSize: 110 * 1024 * 1024 }  // 110 MB
});

const app = express();
const PORT = process.env.NODE_PORT || 3002;

app.use(helmet());
app.use(express.json());

const origin = () => {
  if (process.env.NODE_ENV === 'dev') {
    return 'http://localhost:3000';
  }
  return ["https://collector.sh/", "https://collector-testing-kvak9.ondigitalocean.app/"];
}
app.use(cors({
  origin: origin(),
}))

app.get('/node', (req, res) => {
  res.send('Hello, World!');
});

app.post('/node/upload-metadata',
  uploadMiddleware.single('imageFile'),
  uploadMetadata
)

app.get('/node/health', (req, res) => { res.send("OK!")})

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${ PORT }`);
});