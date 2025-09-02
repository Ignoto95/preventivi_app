const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const lavoriRoutes = require('./routes/lavori');

require('dotenv').config(); // Carica le variabili d'ambiente

const app = express();
const port = 3000;

// Configurazione database MySQL
//const db = mysql.createConnection({
//  host: process.env.DB_HOST,
//  user: process.env.DB_USER,
//  password: process.env.DB_PASSWORD,
//  database: process.env.DB_NAME,
//});
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

db.connect((err) => {
  if (err) {
    console.error('Errore di connessione al database:', err);
  } else {
    console.log('Connesso a MySQL');
  }
});

// Middleware
app.use(cors());
app.use(bodyParser.json());
// Middleware per il parsing JSON
app.use(express.json());


// Rotte API

// 1. Ottieni tutti i preventivi
app.get('/api/preventivi', (req, res) => {
  db.query('SELECT * FROM preventivi', (err, results) => {
    if (err) {
      res.status(500).json({ error: err.message });
    } else {
      res.json(results);
    }
  });
});

// 2. Aggiungi un nuovo preventivo
//app.post('/api/preventivi', (req, res) => {
//  const { codice, ragioneSociale, cliente, fornitore, comune, indirizzo, provincia, partitaIVA } = req.body;
//
 // db.query(
//    'INSERT INTO preventivi (codice, ragioneSociale, cliente, fornitore, comune, indirizzo, provincia, partitaIVA) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
 //   [codice, ragioneSociale, cliente, fornitore, comune, indirizzo, provincia, partitaIVA],
//    (err, results) => {
 //     if (err) {
//        res.status(500).json({ error: err.message });
 //     } else {
//        res.json({ id: results.insertId, ...req.body });
 //     }
//    }
//  );
//});
app.post('/lavoro', async (req, res) => {
  const { id_preventivo, tipo_lavoro, descrizione_lavoro, prezzo, caldaia, data_caldaia } = req.body;

  // Converti il valore di caldaia in 1 (Sì) o 0 (No), gestendo numeri e stringhe
  let caldaiaValue;
  if (typeof caldaia === 'string') {
    caldaiaValue = caldaia.toLowerCase() === 'sì' ? 1 : 0; // Stringa Sì o No
  } else {
    caldaiaValue = caldaia === 1 ? 1 : 0; // Numero 1 o 0
  }

  try {
    await pool.query(
      'INSERT INTO Lavoro (id_preventivo, tipo_lavoro, descrizione_lavoro, prezzo, caldaia, data_caldaia) VALUES (?, ?, ?, ?, ?, ?)',
      [id_preventivo, tipo_lavoro, descrizione_lavoro, prezzo, caldaiaValue, data_caldaia]
    );
    res.json({ message: 'Lavoro aggiunto con successo' });
  } catch (error) {
    console.error('Errore durante l\'aggiunta del lavoro:', error);
    res.status(500).json({ error: 'Errore durante l\'aggiunta del lavoro', details: error.message });
  }
});

 //3.
app.use('/lavoro', lavoriRoutes);

// Avvio del server
//app.listen(port, () => {
//  console.log(`Server in esecuzione su http://localhost:${port}`);
//});
app.listen(3000, '0.0.0.0', () => {
  console.log('Server in esecuzione su http://0.0.0.0:3000');
});



