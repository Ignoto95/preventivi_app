require('dotenv').config();

module.exports = {
  apps: [{
    name: 'imc-backend',
    script: 'server.js',
    instances: 1, // Per server con poche risorse, meglio 1 istanza
    exec_mode: 'fork', // invece di cluster
    max_memory_restart: '800M', // Riavvia se supera 800M
    max_restarts: 3, // Massimo 3 restart attempts
    min_uptime: 5000, // Aspetta almeno 5 secondi prima di considerare un avvio riuscito
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID,
      FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL,
      FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY,
      DB_HOST: process.env.DB_HOST,
      DB_USER: process.env.DB_USER,
      DB_PASSWORD: process.env.DB_PASSWORD,
      DB_NAME: process.env.DB_NAME
    },
    error_file: 'logs/err.log',
    out_file: 'logs/out.log',
    log_file: 'logs/combined.log',
    time: true,
    // Ottimizzazione memoria
    node_args: '--optimize-for-size --max-old-space-size=1024'
  }]
};
