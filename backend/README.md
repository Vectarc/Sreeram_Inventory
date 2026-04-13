# Sree Ram Company — MongoDB Backend API

Full REST API backend for the **Sree Ram Company** Flutter app.  
Built with **Node.js + Express + MongoDB (Mongoose)**.

---

## 📁 Project Structure

```
sreeRam-backend/
├── .env                        ← Environment variables (DB URL, JWT secret)
├── package.json
└── src/
    ├── server.js               ← Entry point
    ├── config/
    │   └── db.js               ← MongoDB connection
    ├── middleware/
    │   └── auth.js             ← JWT protect + adminOnly middleware
    ├── models/
    │   ├── Admin.js            ← Admin model (auto-seeded on startup)
    │   ├── User.js             ← User accounts (created by users)
    │   ├── Product.js          ← Product management
    │   ├── Stock.js            ← Stock levels + transactions
    │   └── Contact.js          ← Contact directory
    └── routes/
        ├── auth.js             ← Login, signup, user management
        ├── products.js         ← Product CRUD + all-shops list
        ├── stock.js            ← Stock CRUD + transactions
        └── contacts.js         ← Contact CRUD
```

---

## ⚙️ Setup & Run

### 1. Prerequisites
- Node.js v18+
- MongoDB installed and running locally  
  → Start MongoDB: `mongod` (or use MongoDB Atlas connection string)

### 2. Install dependencies
```bash
cd sreeRam-backend
npm install
```

### 3. Configure environment
Edit `.env`:
```env
MONGO_URI=mongodb://localhost:27017/sreeram_db
JWT_SECRET=SreeRam_Super_Secret_Key_2024!
PORT=5000
ADMIN_USERNAME=Sreeram
ADMIN_PASSWORD=Sree@123
```

### 4. Start the server
```bash
# Development (auto-restart on changes)
npm run dev

# Production
npm start
```

The server runs at: **http://localhost:5000**

> ✅ On first startup, the **default admin account is automatically created** in MongoDB:  
> **Username:** `Sreeram` | **Password:** `Sree@123`

---

## 🔑 Authentication

All API routes (except login/signup) require a **Bearer token** in the header:

```
Authorization: Bearer <token>
```

Tokens are returned after login and are valid for **7 days**.

| Role  | Access                                                      |
|-------|-------------------------------------------------------------|
| admin | Full access to all CRUD operations                          |
| user  | Read + Create + Update on Products & Stock. Read on others. |

---

## 📡 API Reference

Base URL: `http://localhost:5000/api`

---

### 🔐 Auth Routes (`/api/auth`)

#### Admin Login
```
POST /api/auth/admin/login
Body: { "username": "Sreeram", "password": "Sree@123" }

Response:
{
  "success": true,
  "token": "eyJ...",
  "user": { "id": "...", "username": "Sreeram", "role": "admin" }
}
```

#### User Sign Up (Create Account)
```
POST /api/auth/user/signup
Body: { "username": "john_doe", "password": "secret123" }

Response:
{
  "success": true,
  "message": "Account created successfully. You can now sign in.",
  "user": { "id": "...", "username": "john_doe", "role": "user" }
}
```

#### User Login
```
POST /api/auth/user/login
Body: { "username": "john_doe", "password": "secret123" }

Response:
{
  "success": true,
  "token": "eyJ...",
  "user": { "id": "...", "username": "john_doe", "role": "user" }
}
```

#### Get All Users (Admin only)
```
GET /api/auth/users
Headers: Authorization: Bearer <admin_token>
```

#### Toggle User Active/Inactive (Admin only)
```
PUT /api/auth/users/:id/toggle
Headers: Authorization: Bearer <admin_token>
```

#### Delete User (Admin only)
```
DELETE /api/auth/users/:id
Headers: Authorization: Bearer <admin_token>
```

---

### 📦 Product Management (`/api/products`)

> All routes require `Authorization: Bearer <token>`

#### Get All Products
```
GET /api/products
GET /api/products?category=Category%201
GET /api/products?isActive=true
```

#### Get Single Product
```
GET /api/products/:id
```

#### Create Product
```
POST /api/products
Body:
{
  "name": "Sample Product A",
  "code": "PRD001",
  "unit": "kg",             ← **Unit**: kg, meter, piece, litre, box, dozen, set
  "category": "PLASTISOL",  ← **Category**: PLASTISOL, PRINTING ADD ON, TPL, W/B, NON PVC O/B, STICKER
  "vendor": "vendorId123",  ← **Vendor**: Reference to Vendor ID
  "imageUrl": "https://..."  ← optional
}
```

#### Update Product
```
PUT /api/products/:id
Body: { "name": "New Name", "isActive": false }  ← send only fields to update
```

#### Toggle Active/Inactive
```
PATCH /api/products/:id/toggle
```

#### Delete Product (Admin only)
```
DELETE /api/products/:id
```

#### Get All Products Across All Shops
```
GET /api/products/list/all-shops
```

---

### 🏭 Stock Management (`/api/stock`)

> All routes require `Authorization: Bearer <token>`

#### Get All Stock Levels
```
GET /api/stock
GET /api/stock?branch=Sree%20Ram%20Main
```

#### Get Low Stock Alerts
```
GET /api/stock/alerts
```

#### Initialize Stock for a Product+Branch
```
POST /api/stock
Body:
{
  "productId": "64abc...",
  "branch": "Sree Ram Main",    ← Sree Ram Main | Ramraj Branch
  "quantity": 100,
  "minLevel": 20
}
```

#### Update Minimum Stock Level
```
PUT /api/stock/:id/minlevel
Body: { "minLevel": 30 }
```

#### Delete Stock Entry (Admin only)
```
DELETE /api/stock/:id
```

---

### 📊 Stock Transactions (`/api/stock/transactions`)

#### Get All Transactions
```
GET /api/stock/transactions/all
GET /api/stock/transactions/all?type=purchase
GET /api/stock/transactions/all?branch=Ramraj%20Branch
```

#### Record a Transaction
```
POST /api/stock/transactions
Body (Purchase — adds to stock):
{
  "type": "purchase",
  "productId": "64abc...",
  "quantity": 50,
  "branch": "Sree Ram Main",
  "note": "Received from supplier"
}

Body (Sale — deducts from stock):
{
  "type": "sale",
  "productId": "64abc...",
  "quantity": 10,
  "branch": "Ramraj Branch",
  "note": "Customer sale"
}

Body (Transfer — moves between branches):
{
  "type": "transfer",
  "productId": "64abc...",
  "quantity": 20,
  "fromBranch": "Sree Ram Main",
  "toBranch": "Ramraj Branch",
  "note": "Branch restock"
}

Body (Adjustment — sets absolute quantity):
{
  "type": "adjust",
  "productId": "64abc...",
  "quantity": 75,
  "branch": "Sree Ram Main",
  "note": "Physical count correction"
}
```

#### Delete Transaction (Admin only)
```
DELETE /api/stock/transactions/:id
```

---

### 📞 Contact Directory (`/api/contacts`)

> All routes require `Authorization: Bearer <token>`

#### Get All Contacts
```
GET /api/contacts
GET /api/contacts?category=Transport   ← Transport | Services | Staff | Management
```

#### Get Single Contact
```
GET /api/contacts/:id
```

#### Create Contact
```
POST /api/contacts
Body:
{
  "name": "Ravi Kumar",
  "role": "Transport",
  "phone": "+91 98765 11111",
  "email": "ravi@example.com",    ← optional
  "category": "Transport"
}
```

#### Update Contact
```
PUT /api/contacts/:id
Body: { "phone": "+91 99999 00000" }   ← send only fields to update
```

#### Delete Contact (Admin only)
```
DELETE /api/contacts/:id
```

---

## 🗄️ MongoDB Database Schema Summary

| Collection   | Key Fields                                                         |
|--------------|--------------------------------------------------------------------|
| admins       | username, password (hashed), role                                  |
| users        | username, password (hashed), role, isActive                        |
| products     | name, code (unique), unit, category, imageUrl, isActive, createdBy |
| stocks       | product (ref), productName, branch, quantity, unit, minLevel        |
| transactions | type, product (ref), quantity, branch, fromBranch, toBranch, note  |
| contacts     | name, role, phone, email, category, isActive                       |

---

## 🔗 Connecting Flutter App to This Backend

In your Flutter app, replace the local in-memory store with HTTP calls:

```dart
// Add to pubspec.yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2  // for storing JWT token
```

```dart
// Example: Admin Login
const url = 'http://localhost:5000/api/auth/admin/login';
final response = await http.post(
  Uri.parse(url),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'username': 'Sreeram', 'password': 'Sree@123'}),
);
final data = jsonDecode(response.body);
final token = data['token']; // store this in SharedPreferences
```

---

## 🚀 Deploy to Production

For production, update `.env`:
- Use **MongoDB Atlas** URI: `MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/sreeram_db`
- Use a **strong JWT secret** (32+ random characters)
- Deploy to **Railway**, **Render**, **Heroku**, or any VPS

---

*Built for Sree Ram Company — Quality • Trust • Service*
