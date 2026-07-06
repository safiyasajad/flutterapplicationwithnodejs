import jwt from "jsonwebtoken";
import pool from "../backend config/db.js";

// Middleware used on routes that should only be accessible after login.
// Example: /api/auth/me uses protect before returning the user's profile.
export const protect = async (req, res, next) => {
    try{
        // Flutter sends the JWT in the Authorization header:
        // Authorization: Bearer <token>
        const authHeader = req.headers.authorization;

        // Browser clients may send the JWT in a cookie.
        // Flutter clients send it in the Authorization header.
        const token = req.cookies.token || authHeader?.split(" ")[1];

        // If there is no token, the request is not logged in.
        if(!token) {
            return res.status(401).json({message: "Not authorised, no token"});
        }

        // Verify the JWT signature and decode the user id stored inside it.
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Load the current user's public profile fields from the database.
        // This is what the dashboard displays.
        const user = await pool.query('SELECT id, name,email,phonenumber from users where id = $1', [decoded.id]);

        // If the token is valid but the user no longer exists, reject the request.
        if(user.rows.length === 0) {
            return res.status(401).json({message: "Not authorised, user not found"});
        }

        // Attach the user to req so the next route handler can use it.
        req.user = user.rows[0];

        // Continue to the protected route handler.
        next();


    } catch (error) {
        // Any invalid, expired, or malformed token ends up here.
        console.error(error);
        res.status(401).json({message: "Not authorised, token failed"});
    }
}
