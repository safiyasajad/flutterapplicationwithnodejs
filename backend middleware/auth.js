import jwt from "jsonwebtoken";
import pool from "../backend config/db.js";

export const protect = async (req, res, next) => {
    try{
        const token = req.cookies.token;
        if(!token) {
            return res.status(401).json({message: "Not authorised, no token"});
        }
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await pool.query('SELECT id, name,email from users where id = $1', [decoded.id]);

        if(user.rows.length === 0) {
            return res.status(401).json({message: "Not authorised, user not found"});
        }
            req.user = user.rows[0];
            next();


    } catch (error) {
        console.error(error);
        res.status(401).json({message: "Not authorised, token failed"});
    }
}
