import express from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import pool from "../backend config/db.js";
import {protect} from "../backend middleware/auth.js";

const router = express.Router();

// Cookie settings used when storing the JWT in a browser cookie.
// Flutter also receives the token in the JSON response and stores it locally.
const cookieOptions = {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'Strict',
    maxAge: 30 * 24 * 60 * 60 * 1000

}

// Create a signed JWT containing the user's database id.
// Later, protected routes decode this token to know which user is logged in.
const generateToken = (id) => {
    return jwt.sign({id}, process.env.JWT_SECRET, {
        expiresIn: '30d'
    });
}

// REGISTRATION
// POST /api/auth/register
// Expected body from Flutter: name, email, password, phonenumber.

router.post('/register',async (req,res) => {
    // Pull the submitted fields from the JSON request body.
    const {name, email, password, phonenumber} = req.body;

    // Stop early if any required field is missing or empty.
    if(!name || !email || !password || !phonenumber) {
        return res.status(400).json({message: 'please provide all required fields'}) //makes sure all all fields are filled 
    }

    // Check whether another user already registered with this email address.
    const userExists = await pool.query('SELECT * from users where email = $1',[email]);
    if (userExists.rows.length>0) {
        return res.status(400).json({message: 'user already existes'}); 
    }

    // Hash the password before saving it.
    // Never store plain text passwords in the database.
    const hashedPassword = await bcrypt.hash(password,10);

    // Insert the new user and return safe fields only.
    // The password is intentionally not returned to Flutter.
    const newUser = await pool.query('insert into users (name, email,password,phonenumber) values ($1,$2,$3,$4) returning id, name,email,phonenumber',
    [name, email, hashedPassword, phonenumber]);

    // Create a JWT for the new user so they are logged in immediately.
    const token = generateToken(newUser.rows[0].id);

    // Store the token in a cookie for browser clients.
    res.cookie('token', token, cookieOptions);

    // Return the token too, because Flutter stores it in SharedPreferences.
    return res.status(201).json({token, user: newUser.rows[0]});
})


// LOGIN
// POST /api/auth/login
// Expected body from Flutter: email and password.


router.post('/login',async (req,res) => {
    // Login only needs email and password.
    const { email, password} = req.body;

    // Stop early if either login field is missing.
    if(!email || !password) {
        return res.status(400).json({message: 'please provide all required fields'}) //makes sure all all fields are filled 
    }

    //checks if the entered email exists in database
    const user = await pool.query('SELECT * from users where email = $1',[email]); 
    
    //if no returned rows
    if (user.rows.length == 0){
        return res.status(400).json({message: 'invalid credentials'})

    }
    //else that returned row is the email match 
    const userData =user.rows[0];

    //check that passwords match 
    const isMatch = await bcrypt.compare(password, userData.password);

    //if passwords dont match
    if (!isMatch) {
        return res.status(400).json({message: 'invalid credentials'})

    }
    //if passwords match generate a token and store in cookie
    const token = generateToken(userData.id);
    res.cookie('token', token, cookieOptions);

    // Return safe user data and the JWT for Flutter to store.
    res.json({token, user: {id: userData.id, name:userData.name, email: userData.email, phonenumber: userData.phonenumber}});
})

// CURRENT USER PROFILE
// GET /api/auth/me
// The protect middleware verifies the token and attaches req.user.
router.get('/me',protect, async (req,res) => {
    res.json(req.user)
    //returns informaiton of the logged in user from protect middleware
})

// LOGOUT
// POST /api/auth/logout
// Clears the browser cookie. Flutter also removes the token locally on logout.
router.post('/logout',async (req,res) => {
    res.cookie('token','',{...cookieOptions, maxAge:1});
    res.json({message:'logged out sugessfullt'});
})

router.get('/orders', protect, async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT *
             FROM orders
             //checks the user id of the logged in user and returns all orders made by that user
             WHERE user_id = $1
             ORDER BY ordered_at DESC`,
            [req.user.id]
        );

        // Flutter expects a list, not an object
        res.json(result.rows);

    } catch (error) {
        console.error(error);
        res.status(500).json({
            message: "Failed to fetch orders"
        });
    }
});


//exporting data to be able to use it in server.js
export default router;
