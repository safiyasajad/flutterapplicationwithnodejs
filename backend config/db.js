import {Pool} from 'pg';
import dotenv from 'dotenv';

dotenv.config()

//database connection
const pool = new Pool({
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        database:process.env.DB_NAME,
        user:process.env.DB_USER,
        password: process.env.DB_PASSWORD
        


})

pool.on("connect", ()=>{
    console.log('connected to db');
    
})

pool.on("error", ()=>{
    console.log('error connecting to db');
});


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