import express from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import pool from "../backend config/db.js";
import {protect} from "../backend middleware/auth.js";

const router = express.Router();
const cookieOptions = {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'Strict',
    maxAge: 30 * 24 * 60 * 60 * 1000

}

const generateToken = (id) => {
    return jwt.sign({id}, process.env.JWT_SECRET, {
        expiresIn: '30d'
    });
}

//registeration

router.post('/register',async (req,res) => {
    const {name, email, password, phonenumber} = req.body;
    if(!name || !email || !password || !phonenumber) {
        return res.status(400).json({message: 'please provide all required fields'}) //makes sure all all fields are filled 
    }

    const userExists = await pool.query('SELECT * from users where email = $1',[email]);
    if (userExists.rows.length>0) {
        return res.status(400).json({message: 'user already existes'}); 
    }
    const hashedPassword = await bcrypt.hash(password,10);
    const newUser = await pool.query('insert into users (name, email,password,phonenumber) values ($1,$2,$3,$4) returning id, name,email,phonenumber',
    [name, email, hashedPassword, phonenumber]);

    const token = generateToken(newUser.rows[0].id);

    res.cookie('token', token, cookieOptions);
    return res.status(201).json({user: newUser.rows[0]});
})


//LOGIN


router.post('/login',async (req,res) => {
    const { email, password} = req.body;
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

    //show data when logged in
    res.json({user: {id: userData.id, name:userData.name, email: userData.email}});
})

//showing the data
router.get('/me',protect, async (req,res) => {
    res.json(req.user)
    //returns informaiton of the logged in user from protect middleware
})

//logout
router.post('/logout',async (req,res) => {
    res.cookie('token','',{...cookieOptions, maxAge:1});
    res.json({message:'logged out sugessfullt'});
})
 

//exporting data to be able to use it in server.js
export default router;
