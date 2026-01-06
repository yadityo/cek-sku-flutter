const express = require('express');
const { Pool } = require('pg');
const dotenv = require('dotenv');
dotenv.config();
const cors = require('cors');
const bodyParser = require('body-parser');
const crypto = require('crypto');

const app = express();

// Middleware
app.use(cors({
  origin: '*', // Untuk development, ganti dengan IP spesifik di production
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type']
}));
app.use(bodyParser.json());

// Fungsi hash MD5
const hashMD5 = (str) => {
  return crypto.createHash('md5').update(str).digest('hex');
};

// Pool global
const pool = new Pool({
  host: process.env.PGHOST,
  port: process.env.PGPORT,
  database: process.env.PGDATABASE,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
});

// Fungsi helper untuk koneksi database
const executeQuery = async (dbConfig, queryText, params = []) => {
  // Validasi input sederhana (anti SQL injection)
  if (Array.isArray(params)) {
    for (const p of params) {
      if (typeof p === 'string' && /(;|--|\b(OR|AND)\b)/i.test(p)) {
        throw new Error('Input mengandung karakter tidak valid');
      }
    }
  }
  // Pool query
  const res = await pool.query(queryText, params);
  return res.rows;
};

// Endpoint untuk test koneksi
app.post('/api/test-connection', async (req, res) => {
  const { user: inputStoreCode, password: inputPassword, database } = req.body;
  // Gunakan Pool baru dengan database dari user
  const testPool = new Pool({
    host: process.env.PGHOST,
    port: process.env.PGPORT,
    user: process.env.PGUSER,
    password: process.env.PGPASSWORD,
    database: database || process.env.PGDATABASE,
  });
  try {
    // Coba query sederhana untuk memastikan database benar-benar ada
    try {
      await testPool.query('SELECT 1');
    } catch (dbErr) {
      await testPool.end();
      return res.status(500).json({ status: 'error', message: 'Database tidak ditemukan atau salah'});
    }
    // Password di database harus polos: ganola atau beureum
    // Kolom "Password" di msStoreInfo hanya berisi password tanpa @StoreCode
    const dbPassword = inputPassword.split('@')[0];
    const checkQuery = `
      SELECT "StoreCode" 
      FROM "msStoreInfo" 
      WHERE "StoreCode" = $1 
      AND "Password" = $2
    `;
    const checkResult = await testPool.query(checkQuery, [inputStoreCode, dbPassword]);
    await testPool.end();
    if (checkResult.rows.length > 0) {
      res.json({ status: 'success', message: 'Tes Koneksi Server Berhasil' });
    } else {
      res.status(401).json({ status: 'error', message: 'Store Code atau Password salah' });
    }
  } catch (error) {
    await testPool.end();
    res.status(500).json({ status: 'error', message: error.message });
  }
});
// Endpoint untuk pencarian produk
app.post('/api/search', async (req, res) => {
  console.log('Search request:', req.body);
  const { keyword } = req.body;
  try {
    // Validasi keyword (anti SQL injection)
    if (!keyword || typeof keyword !== 'string' || keyword.trim().length === 0 || /(;|--|\b(OR|AND)\b)/i.test(keyword)) {
      return res.json({ status: 'success', data: [] });
    }
    const query = `
      SELECT 
        "Description" as name, 
        "SKU" as sku, 
        "EndQty" as quantity
      FROM "trStock" 
      WHERE 
        "Description" ILIKE $1 OR 
        "SKU" ILIKE $1
      ORDER BY "LastUpdate" DESC
      LIMIT 1
    `;
    const values = [`%${keyword}%`];
    const products = await pool.query(query, values);
    res.json({ 
      status: 'success', 
      data: products.rows,
      count: products.rowCount 
    });
  } catch (error) {
    console.error('Search error:', error.message);
    res.status(500).json({ 
      status: 'error', 
      message: 'Gagal melakukan pencarian: ' + error.message 
    });
  }
});

// Endpoint untuk health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    message: 'Server berjalan dengan baik',
    timestamp: new Date().toISOString()
  });
});

// Endpoint default
app.get('/', (req, res) => {
  res.send('SKU Checker API Server');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server berjalan di http://0.0.0.0:${PORT}`);
  console.log(`🔗 Local: http://localhost:${PORT}`);
  console.log(`📱 Arahkan Flutter ke IP ini: http://[IP-KOMPUTER]:${PORT}`);
});