-- 1️⃣ DROP EXISTING TABLES (CASCADE handles foreign key dependencies)
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS stocks CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS contacts CASCADE;
DROP TABLE IF EXISTS units CASCADE;
DROP TABLE IF EXISTS branches CASCADE;
DROP TABLE IF EXISTS vendors CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS admins CASCADE;

-- 2️⃣ CREATE TABLES FROM SCRATCH

-- Admins
CREATE TABLE admins (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role TEXT DEFAULT 'admin',
  otp_code TEXT,
  otp_expiry TIMESTAMPTZ,
  otp_attempts INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Users
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  display_password TEXT,
  role TEXT DEFAULT 'user',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Vendors
CREATE TABLE vendors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Branches
CREATE TABLE branches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT,
  phone TEXT,
  email TEXT,
  officeHours TEXT,
  is_main BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Units
CREATE TABLE units (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Contacts
CREATE TABLE contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  role TEXT,
  phone TEXT NOT NULL,
  email TEXT,
  category TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Products
CREATE TABLE products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  unit TEXT DEFAULT 'KG',
  category TEXT NOT NULL,
  brand TEXT DEFAULT '',
  vendor TEXT DEFAULT '',
  image_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_by TEXT DEFAULT 'admin',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Stocks
CREATE TABLE stocks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  product_name TEXT NOT NULL,
  category TEXT NOT NULL,
  branch TEXT NOT NULL,
  quantity NUMERIC DEFAULT 0,
  unit TEXT NOT NULL,
  min_level NUMERIC DEFAULT 10,
  adjustment_alerts JSONB DEFAULT '[]'::JSONB,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Transactions
CREATE TABLE transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('purchase', 'sale', 'transfer', 'adjust')),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  product_name TEXT NOT NULL,
  quantity NUMERIC NOT NULL,
  branch TEXT NOT NULL,
  from_branch TEXT,
  to_branch TEXT,
  note TEXT DEFAULT '',
  created_by TEXT DEFAULT 'admin',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3️⃣ INSERT INITIAL DATA

-- Insert initial units
INSERT INTO units (name) VALUES 
('KG'), ('MTR'), ('PCS'), ('NOS'), ('INCH'), ('LITRE'), ('SHEET'), ('QUIRE'), ('SET')
ON CONFLICT DO NOTHING;

-- Insert default admin account (password is: Sree@123)
-- The password looks like gibberish here because it MUST be immediately encrypted (hashed) 
-- in the database for security reasons.
INSERT INTO admins (username, password) VALUES 
('Sreeram', '$2a$10$WmQfHeyneWn2Z2RyWB/6L.e.yrBb0XaXNmLg0mx4BuZqNbVJe19bq')
ON CONFLICT DO NOTHING;
