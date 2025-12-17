const express = require('express');
const { Client } = require('pg');
const cors = require('cors');
const bodyParser = require('body-parser');
const crypto = require('crypto');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// =========================================================
// KONFIGURASI DATABASE UTAMA (KUNCI UTAMA)
// =========================================================
const DB_USER = 'postgres';
const DB_PASSWORD = 'password';  // GANTI dengan password database PostgreSQL Anda
// =========================================================

// --- FUNGSI HELPER: ENKRIPSI MD5 ---
const hashMD5 = (str) => {
  return crypto.createHash('md5').update(str).digest('hex');
};

// Fungsi Helper Koneksi Database
const executeQuery = async (dbConfig, queryText, params = []) => {
  const client = new Client({
    host: dbConfig.host,
    port: 5432,
    database: dbConfig.database,
    user: DB_USER,
    password: DB_PASSWORD,
  });

  try {
    await client.connect();
    const res = await client.query(queryText, params);
    await client.end();
    return res.rows;
  } catch (err) {
    try { await client.end(); } catch (e) { }
    throw err;
  }
};

// 1. ENDPOINT: TEST KONEKSI & LOGIN (MD5 SUPPORT)
app.post('/api/test-connection', async (req, res) => {
  const { host, user: inputStoreCode, password: inputStorePassword, database } = req.body;

  const client = new Client({
    host,
    port: 5432,
    database,
    user: DB_USER,
    password: DB_PASSWORD,
  });

  try {
    await client.connect();

    // UBAH PASSWORD INPUT MENJADI MD5 SEBELUM DICEK
    const hashedPassword = hashMD5(inputStorePassword);

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
        message: `Login Berhasil! Selamat datang ${inputStoreCode}.`
      });
    } else {
      res.status(401).json({
        status: 'error',
        message: 'Gagal: Store Code atau Password salah.'
      });
    }

  } catch (error) {
    try { await client.end(); } catch (e) { }
    console.error('Login Error:', error.message);

    if (error.message.includes('password authentication failed')) {
      return res.status(500).json({ status: 'error', message: 'Setting Server Salah: Password DB di server/index.js tidak cocok.' });
    }

    res.status(500).json({ status: 'error', message: 'Koneksi Error: ' + error.message });
  }
});

// 2. ENDPOINT: PENCARIAN BARANG (DIFIX: Menambahkan kolom description)
app.post('/api/search', async (req, res) => {
  const { dbConfig, keyword } = req.body;

  try {
    if (!keyword || keyword.trim().length === 0) {
      return res.json({ status: 'success', data: [] });
    }

    const query = `
      SELECT 
        "Description" as name, 
        "SKU" as sku, 
        "EndQty" as quantity,
        "Description" as description 
      FROM "trStock" 
      WHERE 
        "Description" ILIKE $1 OR 
        "SKU" ILIKE $1
      ORDER BY "LastUpdate" DESC
      LIMIT 1
    `;

    const values = [`%${keyword}%`];

    const products = await executeQuery(dbConfig, query, values);

    res.json({ status: 'success', data: products });

  } catch (error) {
    console.error('Search Error:', error.message);
    res.status(500).json({ status: 'error', message: 'Gagal cari: ' + error.message });
  }
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server berjalan di port ${PORT}`);
});