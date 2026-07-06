import {Pool} from 'pg';
import dotenv from 'dotenv';

// Load PostgreSQL connection values from the .env file.
dotenv.config()

// Create a PostgreSQL connection pool.
// A pool lets the app reuse database connections instead of opening a new
// connection for every login/register request.
const pool = new Pool({
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        database:process.env.DB_NAME,
        user:process.env.DB_USER,
        password: process.env.DB_PASSWORD
        


})

// This runs whenever a new database connection is successfully created.
pool.on("connect", ()=>{
    console.log('connected to db');
    
})

// This runs when the pool has a database connection problem.
// The app logs it so you can diagnose wrong credentials, stopped database, etc.
pool.on("error", ()=>{
    console.log('error connecting to db');
});


// Export the pool so route files can run SQL queries with pool.query(...).
export default pool;




// import { Pool } from 'pg';
// import dotenv from 'dotenv';

// dotenv.config();

// console.log({
//   DB_HOST: process.env.DB_HOST,
//   DB_PORT: process.env.DB_PORT,
//   DB_NAME: process.env.DB_NAME,
//   DB_USER: process.env.DB_USER,
//   DB_PASSWORD: process.env.DB_PASSWORD ? '[set]' : '[missing]'
// });

// const pool = new Pool({
//   host: process.env.DB_HOST,
//   port: process.env.DB_PORT,
//   database: process.env.DB_NAME,
//   user: process.env.DB_USER,
//   password: process.env.DB_PASSWORD
// });

// pool.on("connect", () => {
//   console.log('connected to db');
// });

// pool.on("error", () => {
//   console.log('error connecting to db');
// });

// export default pool;
