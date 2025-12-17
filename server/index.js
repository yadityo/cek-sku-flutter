const express = require('express');
const { Client } = require('pg');
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

// Fungsi helper untuk koneksi database
const executeQuery = async (dbConfig, queryText, params = []) => {
  const client = new Client({
    host: dbConfig.host || 'localhost',
    port: 5432,
    database: dbConfig.database,
    user: 'postgres', // User utama PostgreSQL
    password: 'password', // GANTI dengan password PostgreSQL Anda
  });

  try {
    await client.connect();
    const res = await client.query(queryText, params);
    await client.end();
    return res.rows;
  } catch (err) {
    console.error('Database query error:', err.message);
    try { await client.end(); } catch (e) { }
    throw err;
  }
};

// Endpoint untuk test koneksi
app.post('/api/test-connection', async (req, res) => {
  console.log('Test connection request:', req.body);
  
  const { host, user: inputStoreCode, password: inputPassword, database } = req.body;

  try {
    // 1. Hash password yang dikirim dari Flutter
    // const hashedPassword = hashMD5(inputPassword);
    const hashedPassword = inputPassword;
    
    // 2. Coba konek ke database
    const client = new Client({
      host: host || 'localhost',
      port: 5432,
      database: database,
      user: 'postgres',
      password: '', // GANTI dengan password PostgreSQL Anda
    });

    await client.connect();
    
    // 3. Verifikasi store code dan password
    const checkQuery = `
      SELECT "StoreCode" 
      FROM "msStoreInfo" 
      WHERE "StoreCode" = $1 AND "Password" = $2
    `;
    
    const checkResult = await client.query(checkQuery, [inputStoreCode, hashedPassword]);
    await client.end();

    if (checkResult.rows.length > 0) {
      res.json({
        status: 'success',
        message: `Koneksi berhasil! Store: ${inputStoreCode}`
      });
    } else {
      res.status(401).json({
        status: 'error',
        message: 'Store Code atau Password salah'
      });
    }
  } catch (error) {
    console.error('Connection test error:', error.message);
    
    // Pesan error yang lebih spesifik
    let errorMessage = error.message;
    if (error.message.includes('password authentication failed')) {
      errorMessage = 'Password database PostgreSQL salah. Periksa konfigurasi server.';
    } else if (error.message.includes('does not exist')) {
      errorMessage = 'Database tidak ditemukan';
    } else if (error.message.includes('connect')) {
      errorMessage = 'Tidak dapat terhubung ke database';
    }
    
    res.status(500).json({
      status: 'error',
      message: errorMessage
    });
  }
});

// Endpoint untuk pencarian produk
app.post('/api/search', async (req, res) => {
  console.log('Search request:', req.body);
  
  const { keyword, dbConfig } = req.body;

  try {
    if (!keyword || keyword.trim().length === 0) {
      return res.json({ status: 'success', data: [] });
    }

    // Hash password dari Flutter untuk koneksi
    const hashedPassword = dbConfig.password;
    
    // Update dbConfig dengan password yang sudah di-hash
    const updatedDbConfig = {
      ...dbConfig,
      password: hashedPassword
    };

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
    
    const products = await executeQuery(updatedDbConfig, query, values);
    
    res.json({ 
      status: 'success', 
      data: products,
      count: products.length 
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