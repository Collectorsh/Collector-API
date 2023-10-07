import Knex from 'knex';

const postgres = Knex({
  client: "pg",
  connection: process.env.DATABASE_URL,
  // searchPath: [process.env.DB_USERNAME, 'public'],
});

export default postgres;