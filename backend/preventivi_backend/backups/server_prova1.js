const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const { PDFDocument } = require('pdf-lib');
const fs = require('fs');
const path = require('path');
require('dotenv').config(); // Carica le variabili d'ambiente
const { PDFDocument, StandardFonts } = require('pdf-lib');
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
//app.use(cors());
app.use(cors({
  origin: '*', // Permetti tutte le origini
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));


app.use(bodyParser.json());

// Route per l'inserimento del preventivo, cliente e lavori
app.post('/preventivo', async (req, res) => {
  let { data_preventivo, id_cliente, prezzo_totale, lavori, cliente } = req.body;

  if (!cliente || !lavori || lavori.length === 0 || !data_preventivo) {
    return res.status(400).json({ error: 'Dati mancanti: verifica di aver inserito cliente, data e lavori.' });
  }

  const connection = await pool.promise().getConnection();
  try {
    // Inizia la transazione
    await connection.beginTransaction();

    // 1. Controlla se il cliente esiste
    const [clientResult] = await connection.query(
      'SELECT id_cliente FROM Cliente WHERE id_cliente = ?',
      [id_cliente]
    );

    if (clientResult.length === 0) {
      const { nome, cognome, citta, via } = cliente;
      const [insertClientResult] = await connection.query(
        'INSERT INTO Cliente (nome, cognome, citta, via) VALUES (?, ?, ?, ?)',
        [nome, cognome, citta, via]
      );
      id_cliente = insertClientResult.insertId; // Nuovo cliente
    }

    // 2. Inserisci il preventivo
    const [result] = await connection.query(
      'INSERT INTO Preventivo (data_preventivo, id_cliente, prezzo_totale) VALUES (?, ?, ?)',
      [data_preventivo, id_cliente, prezzo_totale || 0]
    );
    const id_preventivo = result.insertId;

    // 3. Inserisci i lavori
    for (const lavoro of lavori) {
      const { tipo_lavoro, descrizione_lavoro, prezzo } = lavoro;
      await connection.query(
        'INSERT INTO Lavoro (id_preventivo, tipo_lavoro, descrizione_lavoro, prezzo) VALUES (?, ?, ?, ?)',
        [id_preventivo, tipo_lavoro, descrizione_lavoro, prezzo]
      );
    }

    // 4. Ricalcola il prezzo totale se non specificato
    if (!prezzo_totale) {
      await connection.query(
        'UPDATE Preventivo SET prezzo_totale = (SELECT IFNULL(SUM(prezzo), 0) FROM Lavoro WHERE id_preventivo = ?) WHERE id_preventivo = ?',
        [id_preventivo, id_preventivo]
      );
    }

    await connection.commit();
    res.status(201).json({ message: 'Preventivo, cliente e lavori inseriti con successo', id_preventivo });
  } catch (err) {
    await connection.rollback();
    console.error(err);
    res.status(500).json({ error: 'Errore durante l\'inserimento del preventivo.' });
  } finally {
    connection.release();
  }
});

// Nuova Route per ottenere tutti i preventivi e i dettagli correlati
app.get('/preventivi', async (req, res) => {
  const connection = await pool.promise().getConnection();
  try {
    const [rows] = await connection.query(`
      SELECT
        p.id_preventivo,
        p.data_preventivo,
        p.prezzo_totale,
        c.nome AS nome_cliente,
        c.cognome AS cognome_cliente,
        c.citta,
        c.via,
        l.id_lavoro,
        l.tipo_lavoro,
        l.descrizione_lavoro,
        l.prezzo
      FROM
        Preventivo p
      JOIN
        Cliente c ON p.id_cliente = c.id_cliente
      LEFT JOIN
        Lavoro l ON p.id_preventivo = l.id_preventivo
    `);

    // Organizzare i dati in un formato strutturato
    const preventivi = rows.reduce((acc, row) => {
      const existingPreventivo = acc.find(p => p.id_preventivo === row.id_preventivo);
      if (existingPreventivo) {
        existingPreventivo.lavori.push({
          id_lavoro: row.id_lavoro,
          tipo_lavoro: row.tipo_lavoro,
          descrizione_lavoro: row.descrizione_lavoro,
          prezzo: row.prezzo
        });
      } else {
        acc.push({
          id_preventivo: row.id_preventivo,
          data_preventivo: row.data_preventivo,
          prezzo_totale: row.prezzo_totale,
          nome_cliente: row.nome_cliente,
          cognome_cliente: row.cognome_cliente,
          citta: row.citta,
          via: row.via,
          lavori: [{
            id_lavoro: row.id_lavoro,
            tipo_lavoro: row.tipo_lavoro,
            descrizione_lavoro: row.descrizione_lavoro,
            prezzo: row.prezzo
          }]
        });
      }
      return acc;
    }, []);

    res.status(200).json(preventivi);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Errore durante il recupero dei preventivi' });
  } finally {
    connection.release();
  }
});
//GET per modifica ai PDF (aggiunta dell':id)
app.get('/preventivo/:id', async (req, res) => {
  const preventivoId = req.params.id;
  const connection = await pool.promise().getConnection();
  try {
    // La tua query per ottenere il preventivo con l'id
    const [rows] = await connection.query(`
      SELECT
        p.id_preventivo,
        p.data_preventivo,
        p.prezzo_totale,
        c.nome AS nome_cliente,
        c.cognome AS cognome_cliente,
        c.citta,
        c.via,
        l.id_lavoro,
        l.tipo_lavoro,
        l.descrizione_lavoro,
        l.prezzo
      FROM
        Preventivo p
      JOIN
        Cliente c ON p.id_cliente = c.id_cliente
      LEFT JOIN
        Lavoro l ON p.id_preventivo = l.id_preventivo
      WHERE
        p.id_preventivo = ?
    `, [preventivoId]);

    // Organizza i dati in un formato strutturato
    const preventivo = rows.reduce((acc, row) => {
      if (acc) {
        acc.lavori.push({
          id_lavoro: row.id_lavoro,
          tipo_lavoro: row.tipo_lavoro,
          descrizione_lavoro: row.descrizione_lavoro,
          prezzo: row.prezzo
        });
      } else {
        acc = {
          id_preventivo: row.id_preventivo,
          data_preventivo: row.data_preventivo,
          prezzo_totale: row.prezzo_totale,
          nome_cliente: row.nome_cliente,
          cognome_cliente: row.cognome_cliente,
          citta: row.citta,
          via: row.via,
          lavori: [{
            id_lavoro: row.id_lavoro,
            tipo_lavoro: row.tipo_lavoro,
            descrizione_lavoro: row.descrizione_lavoro,
            prezzo: row.prezzo
          }]
        };
      }
      return acc;
    }, null);

    if (preventivo) {
      res.status(200).json(preventivo);
    } else {
      res.status(404).json({ error: 'Preventivo non trovato' });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Errore durante il recupero del preventivo' });
  } finally {
    connection.release();
  }
});




// Rimozione preventivo
app.delete('/preventivo/:id', async (req, res) => {
  const preventivoId = req.params.id; // Ottieni l'ID del preventivo dalla URL

  const connection = await pool.promise().getConnection();
  try {
    // Inizia la transazione
    await connection.beginTransaction();

    // Rimuovi i lavori associati al preventivo
    await connection.query('DELETE FROM Lavoro WHERE id_preventivo = ?', [preventivoId]);

    // Rimuovi il preventivo
    const [result] = await connection.query('DELETE FROM Preventivo WHERE id_preventivo = ?', [preventivoId]);

    if (result.affectedRows > 0) {
      // Conferma la transazione
      await connection.commit();
      res.status(200).json({ message: 'Preventivo eliminato con successo' });
    } else {
      // Se non ci sono righe eliminate, il preventivo non esiste
      res.status(404).json({ error: 'Preventivo non trovato' });
    }
  } catch (err) {
    // In caso di errore, rollback della transazione
    await connection.rollback();
    console.error(err);
    res.status(500).json({ error: 'Errore durante l\'eliminazione del preventivo' });
  } finally {
    // Rilascia la connessione
    connection.release();
  }
});

// Route per aggiornare i lavori associati a un preventivo
app.put('/preventivo/lavori/:id', async (req, res) => {
  const preventivoId = req.params.id;
  const lavori = req.body.lavori; // Lavori è un array di oggetti lavoro

  const connection = await pool.promise().getConnection();
  try {
    // Inizia la transazione
    await connection.beginTransaction();

    // 1. Rimuovi i lavori esistenti per quel preventivo
    await connection.query('DELETE FROM Lavoro WHERE id_preventivo = ?', [preventivoId]);

    // 2. Aggiungi i nuovi lavori
    for (const lavoro of lavori) {
      const { tipo_lavoro, descrizione_lavoro, prezzo } = lavoro;

      await connection.query(
        'INSERT INTO Lavoro (id_preventivo, tipo_lavoro, descrizione_lavoro, prezzo) VALUES (?, ?, ?, ?)',
        [preventivoId, tipo_lavoro, descrizione_lavoro, prezzo]
      );
    }

    // 3. Aggiorna il prezzo totale del preventivo dopo la modifica dei lavori
    await connection.query(
      'UPDATE Preventivo SET prezzo_totale = (SELECT IFNULL(SUM(prezzo), 0) FROM Lavoro WHERE id_preventivo = ?) WHERE id_preventivo = ?',
      [preventivoId, preventivoId]
    );

    // Conferma la transazione
    await connection.commit();

    res.status(200).json({ message: 'Lavori aggiornati con successo' });
  } catch (err) {
    // In caso di errore, rollback della transazione
    await connection.rollback();
    console.error(err);
    res.status(500).json({ error: 'Errore durante l\'aggiornamento dei lavori' });
  } finally {
    // Rilascia la connessione
    connection.release();
  }
});

// Route che permette la generazione del PDF
app.get('/generate-pdf/:id', async (req, res) => {
  const preventivoId = req.params.id;
  const connection = await pool.promise().getConnection();

  try {
    // Ottieni i dettagli del preventivo e dei lavori dal database
    const [rows] = await connection.query(`
      SELECT
        p.id_preventivo,
        p.data_preventivo,
        p.prezzo_totale,
        c.nome AS nome_cliente,
        c.cognome AS cognome_cliente,
        c.citta,
        c.via,
        l.tipo_lavoro,
        l.descrizione_lavoro,
        l.prezzo
      FROM
        Preventivo p
      JOIN
        Cliente c ON p.id_cliente = c.id_cliente
      LEFT JOIN
        Lavoro l ON p.id_preventivo = l.id_preventivo
      WHERE
        p.id_preventivo = ?
    `, [preventivoId]);

    // Organizza i dati in un formato strutturato
    const preventivo = rows.reduce((acc, row) => {
      if (acc) {
        acc.lavori.push({
          tipo_lavoro: row.tipo_lavoro,
          descrizione_lavoro: row.descrizione_lavoro,
          prezzo: row.prezzo
        });
      } else {
        acc = {
          id_preventivo: row.id_preventivo,
          data_preventivo: row.data_preventivo,
          prezzo_totale: row.prezzo_totale,
          nome_cliente: row.nome_cliente,
          cognome_cliente: row.cognome_cliente,
          citta: row.citta,
          via: row.via,
          lavori: [{
            tipo_lavoro: row.tipo_lavoro,
            descrizione_lavoro: row.descrizione_lavoro,
            prezzo: row.prezzo
          }]
        };
      }
      return acc;
    }, null);

    if (!preventivo) {
      return res.status(404).json({ error: 'Preventivo non trovato' });
    }

    // Crea un nuovo documento PDF
    const pdfDoc = await PDFDocument.create();

    // Aggiungi una pagina al documento PDF
    const page = pdfDoc.addPage();
    const { width, height } = page.getSize();

    // Imposta il font per il testo
    const font = await pdfDoc.embedFont(PDFDocument.Font.Helvetica);

    let yPosition = height - 50;

    // Aggiungi i dettagli del preventivo e cliente al PDF
    page.drawText(`Preventivo #: ${preventivo.id_preventivo}`, { x: 50, y: yPosition, size: 14, font });
    yPosition -= 20;
    page.drawText(`Cliente: ${preventivo.nome_cliente} ${preventivo.cognome_cliente}`, { x: 50, y: yPosition, size: 12, font });
    yPosition -= 20;
    page.drawText(`Indirizzo: ${preventivo.via}, ${preventivo.citta}`, { x: 50, y: yPosition, size: 12, font });
    yPosition -= 20;
    page.drawText(`Data: ${preventivo.data_preventivo}`, { x: 50, y: yPosition, size: 12, font });
    yPosition -= 20;

    // Aggiungi i dettagli dei lavori
    page.drawText('Lavori:', { x: 50, y: yPosition, size: 12, font });
    yPosition -= 20;

    preventivo.lavori.forEach((lavoro, index) => {
      page.drawText(`${index + 1}. ${lavoro.tipo_lavoro}: ${lavoro.descrizione_lavoro} - €${lavoro.prezzo}`, { x: 50, y: yPosition, size: 12, font });
      yPosition -= 20;
    });

    // Aggiungi il prezzo totale
    page.drawText(`Totale: €${preventivo.prezzo_totale}`, { x: 50, y: yPosition, size: 12, font });

    // Salva il PDF generato in un buffer
    const pdfBytes = await pdfDoc.save();

    // Imposta l'intestazione della risposta per il download del PDF
    res.contentType('application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=preventivo.pdf');
    res.send(pdfBytes);

  } catch (error) {
    console.error('Errore durante la generazione del PDF:', error);
    res.status(500).json({ error: 'Errore durante la generazione del PDF' });
  } finally {
    connection.release();
  }
});



// Avvio del server
app.listen(port, () => {
  console.log(`Server in ascolto sulla porta ${port}`);
});

