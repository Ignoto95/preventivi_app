const express = require('express');
const path = require('path');
const cors = require('cors');
const middlewares = require('./middlewares');
const pool = require('./config/db');
const dotenv = require('dotenv');
const rateLimit = require('express-rate-limit');
//require('dotenv').config();
///dotenv.config({ path: path.resolve(__dirname, '.env') });
const app = express();
const port = process.env.PORT || 3000;
// Rate limiting globale per prevenire abusi
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuti
  max: 100, // massimo 100 richieste per IP ogni 15 minuti
  message: {
    error: "Troppe richieste da questo IP, riprova più tardi."
  }
});

// 1. MIDDLEWARE FONDAMENTALI PRIMA DI TUTTO
app.set('trust proxy', 1);
app.use(globalLimiter);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 2. CORS
app.use(cors({
  origin: [
    'https://www.imcimpianti.cloud',
    'https://imcimpianti.cloud',
    'http://localhost:5000' // mantieni per sviluppo
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// 3. MIDDLEWARE PERSONALIZZATI
middlewares.staticFiles(app);

// 4. ROUTES (DOPO TUTTI I MIDDLEWARE NECESSARI)
const routes = [
  require('./routes/clienti'),
  require('./routes/preventivi'),
  require('./routes/documenti'),
  require('./routes/allegati'),
  require('./routes/condizionatori'),
  require('./routes/statistiche'),
];

routes.forEach(route => app.use('/api', route));

// 5. AVVIO SERVER
app.listen(port, () => {
  console.log(`Server in ascolto sulla porta ${port}`);
});

