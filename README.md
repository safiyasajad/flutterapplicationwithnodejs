# Flutter Order History App with Node.js and PostgreSQL

This project is a full-stack order history application built with a Flutter frontend, a Node.js/Express backend, and a PostgreSQL database. Users can register, log in, view their profile details, create orders, search orders, filter orders by price range, sort orders by date created, color-code order statuses, and delete orders.

## Project Overview

The application has two main parts:

- Flutter frontend: Handles login, registration, dashboard UI, order creation, order list display, search, filtering, sorting, and logout.
- Node.js backend: Provides REST API routes for authentication, user profile loading, order creation, order fetching, and order deletion.
- PostgreSQL database: Stores user accounts and orders.

The backend uses JWT authentication. After login or registration, the Flutter app stores the JWT in `SharedPreferences` and sends it in the `Authorization` header when calling protected API routes.

## Main Features

- User registration with name, email, password, and phone number.
- User login with email and password.
- Password hashing using `bcryptjs`.
- JWT-based authentication using `jsonwebtoken`.
- Protected profile route: `GET /api/auth/me`.
- Create orders with item name, quantity, price, and status.
- View logged-in user's orders only.
- Search orders by item name.
- Sort orders by date created.
- Filter orders by minimum and maximum price.
- Color-coded order statuses:
  - `Delivered` = green
  - `Preparing` = yellow
  - `Out for Delivery` = orange
  - `Cancelled` = red
- Delete orders from both the app UI and PostgreSQL database.
- Logout by removing the saved token.

## Tech Stack

### Frontend

- Flutter
- Dart
- `http` package for API calls
- `shared_preferences` for saving the JWT locally

### Backend

- Node.js
- Express
- PostgreSQL
- `pg` for PostgreSQL connection
- `bcryptjs` for password hashing
- `jsonwebtoken` for JWT creation and verification
- `cookie-parser`
- `cors`
- `dotenv`
- `nodemon` for development

## Project Structure

```text
.
+-- backend config/
|   +-- db.js
+-- backend middleware/
|   +-- auth.js
+-- backend routes/
|   +-- auth.js
+-- lib/
|   +-- dashboard.dart
|   +-- login.dart
|   +-- main.dart
+-- server.js
+-- package.json
+-- pubspec.yaml
+-- README.md
```

## Important Files

### `server.js`

Starts the Express backend server, enables JSON request parsing, enables cookies, configures CORS, and mounts the authentication/order API routes under:

```text
/api/auth
```

The backend runs on:

```text
http://localhost:5000
```

unless another port is provided in the `.env` file.

### `backend config/db.js`

Creates the PostgreSQL connection pool using environment variables:

```text
DB_HOST
DB_PORT
DB_NAME
DB_USER
DB_PASSWORD
```

### `backend middleware/auth.js`

Contains the `protect` middleware. This middleware:

- Reads the token from the `Authorization` header or cookie.
- Verifies the JWT.
- Loads the logged-in user's public details from the database.
- Attaches the user to `req.user`.
- Blocks requests if the token is missing or invalid.

### `backend routes/auth.js`

Contains the main API routes for:

- Register
- Login
- Logout
- Current user profile
- Create order
- Fetch orders
- Delete order

### `lib/login.dart`

Contains the login and registration screen. It sends authentication requests to the backend and stores the JWT token in `SharedPreferences`.

### `lib/dashboard.dart`

Contains the dashboard and order history UI. It:

- Loads the logged-in user's profile.
- Loads orders from the backend.
- Creates new orders.
- Deletes orders.
- Searches orders by item name.
- Sorts orders by created date.
- Filters orders by price range.
- Displays order status with different colors.
- Logs the user out.

## Environment Variables

Create a `.env` file in the project root for the backend:

```env
PORT=5000
JWT_SECRET=your_jwt_secret_here
DB_HOST=localhost
DB_PORT=5432
DB_NAME=your_database_name
DB_USER=your_database_user
DB_PASSWORD=your_database_password
NODE_ENV=development
```

Replace the database values with your own PostgreSQL details.

## Database Setup

This app expects two main tables: `users` and `orders`.

Example PostgreSQL schema:

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  password TEXT NOT NULL,
  phonenumber VARCHAR(30) NOT NULL
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_name VARCHAR(150) NOT NULL,
  quantity INTEGER NOT NULL,
  price NUMERIC(10, 2) NOT NULL,
  status VARCHAR(50) NOT NULL,
  ordered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

The `ordered_at` column is important because the dashboard uses it to sort orders by date created.

## Backend Setup

Install Node.js dependencies:

```bash
npm install
```

Start the backend in development mode:

```bash
npm run dev
```

Or start it normally:

```bash
npm start
```

If the backend starts successfully, you should see output similar to:

```text
Server listening on port http://localhost:5000
connected to db
```

You can test the root route in a browser:

```text
http://localhost:5000/
```

It should return:

```text
Hello world
```

## Flutter Setup

Install Flutter packages:

```bash
flutter pub get
```

Run the Flutter app:

```bash
flutter run
```

## API Base URL

The Flutter app currently uses this base URL:

```dart
final String baseUrl = 'http://10.0.2.2:5000/api/auth';
```

This is correct for the Android emulator because `10.0.2.2` points to your computer's localhost.

If you run the Flutter app on Chrome, Windows desktop, or another desktop platform, use:

```dart
final String baseUrl = 'http://localhost:5000/api/auth';
```

If you run the app on a real phone, use your computer's local network IP address instead, for example:

```dart
final String baseUrl = 'http://192.168.1.10:5000/api/auth';
```

Your phone and computer must be on the same network.

## API Routes

All routes are mounted under:

```text
/api/auth
```

### Register

```http
POST /api/auth/register
```

Request body:

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "phonenumber": "0712345678"
}
```

Success response:

```json
{
  "token": "jwt_token_here",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phonenumber": "0712345678"
  }
}
```

### Login

```http
POST /api/auth/login
```

Request body:

```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

Success response:

```json
{
  "token": "jwt_token_here",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phonenumber": "0712345678"
  }
}
```

### Get Current User

```http
GET /api/auth/me
```

Headers:

```http
Authorization: Bearer jwt_token_here
```

Success response:

```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "phonenumber": "0712345678"
}
```

### Logout

```http
POST /api/auth/logout
```

This clears the backend cookie. The Flutter app also removes the saved token locally.

### Create Order

```http
POST /api/auth/orders
```

Headers:

```http
Authorization: Bearer jwt_token_here
Content-Type: application/json
```

Request body:

```json
{
  "item_name": "Burger",
  "quantity": 2,
  "price": 1200.00,
  "status": "Preparing"
}
```

Valid status values:

```text
Preparing
Out for Delivery
Delivered
Cancelled
```

### Get Orders

```http
GET /api/auth/orders
```

Headers:

```http
Authorization: Bearer jwt_token_here
```

This returns only the orders that belong to the logged-in user.

The backend orders them by:

```sql
ORDER BY ordered_at DESC
```

### Delete Order

```http
DELETE /api/auth/orders/:id
```

Headers:

```http
Authorization: Bearer jwt_token_here
```

The delete route checks both:

- the order id
- the logged-in user's id

This prevents one user from deleting another user's order.

## Frontend Workflow

### Login and Registration

The app starts on the login page. Users can switch between login and sign-up mode.

On successful login or registration:

1. The backend returns a JWT.
2. Flutter stores the JWT in `SharedPreferences`.
3. The app navigates to the dashboard.

### Dashboard

The dashboard loads:

- The current user's details from `GET /api/auth/me`.
- The user's orders from `GET /api/auth/orders`.

### Order History

The order history page supports:

- Searching by item name.
- Sorting by newest or oldest order.
- Filtering by minimum and maximum price.
- Deleting an order from the popup menu.
- Viewing status colors.

### Create Order Dialog

The floating action button opens a create order dialog. The form includes:

- Item name
- Quantity
- Price
- Status dropdown

When an order is created successfully:

1. The dialog closes.
2. The input fields are cleared.
3. The order list reloads from the backend.

## Troubleshooting

### Flutter cannot connect to backend

Check the base URL in `login.dart` and `dashboard.dart`.

Use this for Android emulator:

```text
http://10.0.2.2:5000/api/auth
```

Use this for desktop or Chrome:

```text
http://localhost:5000/api/auth
```

Use your computer's local IP address for a real phone.

### Token errors

If protected routes fail with an authorization error:

- Make sure `JWT_SECRET` exists in `.env`.
- Log in again so Flutter saves a fresh token.
- Check that requests include:

```http
Authorization: Bearer your_token_here
```

### Database connection errors

Check:

- PostgreSQL is running.
- The database exists.
- The `.env` database values are correct.
- The `users` and `orders` tables exist.

### Orders do not sort by date

Make sure the `orders` table has:

```sql
ordered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
```

## Useful Commands

Install backend dependencies:

```bash
npm install
```

Run backend:

```bash
npm run dev
```

Install Flutter dependencies:

```bash
flutter pub get
```

Run Flutter:

```bash
flutter run
```

Format Dart code:

```bash
dart format lib
```

## Learning References

These are the tutorial links used while building the project:

- PostgreSQL and API tutorial: https://www.youtube.com/watch?v=b8tGF2A6ZnY   until minuite 37
- Frontend tutorial: https://www.youtube.com/watch?v=qFdUdGn_34M

