import Knex from 'knex';
import fs from 'fs'


import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export function resolvePath(relativePath) {
  return join(__dirname, relativePath);
}

const postgres = Knex({
  client: "pg",
  // connection: process.env.DATABASE_URL,
  connection: {
    ssl: {
      ca: fs.readFileSync(resolvePath('../ca-certificate.crt')).toString(),
      rejectUnauthorized: true
    },
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE
  },
 
});

export default postgres;