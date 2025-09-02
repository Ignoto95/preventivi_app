const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
require('dotenv').config(); // Carica le variabili d'ambiente

const app = express();
const port = 3000;

// Configurazione del pool di connessione MySQL
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Route per l'inserimento del preventivo, cliente e lavori
app.post('/preventivo', async (req, res) => {
  let { data_preventivo, id_cliente, prezzo_totale, lavori, cliente } = req.body;  // `lavori` è un array di oggetti lavoro

  const connection = await pool.promise().getConnection();
  try {
    // Inizia la transazione
    await connection.beginTransaction();

    // 1. Controlla se il cliente esiste
    const [clientResult] = await connection.query(
      'SELECT id_cliente FROM Cliente WHERE id_cliente = ?',
      [id_cliente]
    );

    // Se il cliente non esiste, lo inseriamo
    if (clientResult.length === 0) {
      // Estrai i dati del cliente dalla richiesta
      const { nome, cognome, citta, via } = cliente;
      const [insertClientResult] = await connection.query(
        'INSERT INTO Cliente (nome, cognome, citta, via) VALUES (?, ?, ?, ?)',
        [nome, cognome, citta, via]
      );
      id_cliente = insertClientResult.insertId;  // Otteniamo l'ID del nuovo cliente
    }

    // 2. Inserisci il preventivo
    const [result] = await connection.query(
      'INSERT INTO Preventivo (data_preventivo, id_cliente, prezzo_totale) VALUES (?, ?, ?)',
      [data_preventivo, id_cliente, prezzo_totale]
    );
    const id_preventivo = result.insertId;  // Ottieni l'id del preventivo appena creato

    // 3. Inserisci i lavori associati al preventivo
    for (const lavoro of lavori) {
      // Estrai i dati del lavoro
      const { tipo_lavoro, descrizione_lavoro, prezzo } = lavoro;

      // Inserisci il lavoro nel database
      await connection.query(
        'INSERT INTO Lavoro (id_preventivo, tipo_lavoro, descrizione_lavoro, prezzo) VALUES (?, ?, ?, ?)',
        [id_preventivo, tipo_lavoro, descrizione_lavoro, prezzo]
      );
    }

    // 4. Aggiorna il prezzo totale del preventivo
    await connection.query(
      'UPDATE Preventivo SET prezzo_totale = (SELECT IFNULL(SUM(prezzo), 0) FROM Lavoro WHERE id_preventivo = ?) WHERE id_preventivo = ?',
      [id_preventivo, id_preventivo]
    );

    // Conferma la transazione
    await connection.commit();

    res.status(201).json({ message: 'Preventivo, cliente e lavori inseriti con successo', id_preventivo });
  } catch (err) {
    // In caso di errore, rollback della transazione
    await connection.rollback();
    console.error(err);
    res.status(500).json({ error: 'Errore durante l\'inserimento del preventivo, cliente e dei lavori' });
  } finally {
    // Rilascia la connessione
    connection.release();
  }
});

// Avvio del server
app.listen(port, '0.0.0.0', () => {
  console.log(`Server in esecuzione su http://0.0.0.0:${port}`);
});

