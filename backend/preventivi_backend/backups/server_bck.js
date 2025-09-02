const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const lavoriRoutes = require('./routes/lavori');

require('dotenv').config(); // Carica le variabili d'ambiente

const app = express();
const port = 3000;

// Configurazione database MySQL
const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
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
app.post('/api/preventivi', (req, res) => {
  const { codice, ragioneSociale, cliente, fornitore, comune, indirizzo, provincia, partitaIVA } = req.body;

  db.query(
    'INSERT INTO preventivi (codice, ragioneSociale, cliente, fornitore, comune, indirizzo, provincia, partitaIVA) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [codice, ragioneSociale, cliente, fornitore, comune, indirizzo, provincia, partitaIVA],
    (err, results) => {
      if (err) {
        res.status(500).json({ error: err.message });
      } else {
        res.json({ id: results.insertId, ...req.body });
      }
    }
  );
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


