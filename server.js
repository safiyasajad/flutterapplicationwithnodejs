import express from "express";
import dotenv from"dotenv";
import cookieParser from "cookie-parser";
import cors from "cors";
import authRoutes from "./backend routes/auth.js";

// Load variables from .env, such as PORT, database credentials, and JWT_SECRET.
dotenv.config();

const app = express();

// Allow requests from the frontend development URL.
// credentials: true allows cookies to be sent for browser clients.
app.use(cors({
    origin: 'http://localhost:5173',
    credentials: true
}));


// Parse incoming JSON request bodies so req.body contains form data from Flutter.
app.use(express.json());

// Parse cookies so protected routes can read the JWT cookie when a browser sends it.
app.use(cookieParser());


// Simple test route. Opening http://localhost:5000/ should show "Hello world".
app.get('/',(req,res)=>{
    res.send("Hello world")
})

// Mount all authentication routes under /api/auth.
// Example final URLs: /api/auth/register, /api/auth/login, /api/auth/me.
app.use('/api/auth', authRoutes); 



// Start the Express server on the .env PORT or default to 5000.
const PORT = process.env.PORT || 5000;
app.listen(PORT,()=>{
    console.log(`Server listening on port http://localhost:${PORT}`);
});
