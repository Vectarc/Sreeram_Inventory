require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const { checkConnection } = require('./config/supabase');

const app = express();

// ── Connect to Supabase ─────────────────────────────────────────────
checkConnection().then(() => {
  console.log('✅ Ready to serve requests with Supabase backend.');
});

// ── CORS — allow Flutter Web, mobile, Postman ──────────────────────
const corsOptions = {
  origin: (origin, callback) => callback(null, true),
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

// ── Middleware ──────────────────────────────────────────────────────
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// ── Routes ──────────────────────────────────────────────────────────
app.use('/api/auth', require('./routes/auth'));
app.use('/api/products', require('./routes/products'));
app.use('/api/stock', require('./routes/stock'));
app.use('/api/contacts', require('./routes/contacts'));
app.use('/api/branches', require('./routes/branches'));
app.use('/api/vendors', require('./routes/vendors'));
app.use('/api/units', require('./routes/units'));

// ── Privacy Policy ──────────────────────────────────────────────────
app.get('/privacy', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/privacy.html'));
});

// ── Health Check ────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Sree Ram Company API is running',
    timestamp: new Date().toISOString(),
  });
});

// ── 404 Handler ─────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.method} ${req.url} not found.` });
});

// ── Global Error Handler ─────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Internal server error.' });
});

// ── Start Server ─────────────────────────────────────────────────────
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`\nServer running on http://localhost:${PORT}`);
  console.log(`API Base: http://localhost:${PORT}/api`);
  console.log(`Health:  http://localhost:${PORT}/api/health\n`);
});
