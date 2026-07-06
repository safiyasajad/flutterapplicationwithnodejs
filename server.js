import express from "express";
import dotenv from"dotenv";
import cookieParser from "cookie-parser";
import cors from "cors";
import authRoutes from "./backend routes/auth.js";

dotenv.config();
const app = express();

app.use(cors({
    origin: 'http://localhost:5173',
    credentials: true
}));


app.use(express.json());
app.use(cookieParser());


app.get('/',(req,res)=>{
    res.send("Hello world")
})

app.use('/api/auth', authRoutes); 



const PORT = process.env.PORT || 5000;
app.listen(PORT,()=>{
    console.log(`Server listening on port http://localhost:${PORT}`);
});