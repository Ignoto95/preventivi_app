const admin = require('firebase-admin');

if (!admin.apps.length) {
  try {
    // DEBUG: Log delle variabili d'ambiente
    console.log('FIREBASE_PROJECT_ID:', process.env.FIREBASE_PROJECT_ID);
    console.log('FIREBASE_CLIENT_EMAIL:', process.env.FIREBASE_CLIENT_EMAIL);
    console.log('FIREBASE_PRIVATE_KEY present:', !!process.env.FIREBASE_PRIVATE_KEY);

    if (!process.env.FIREBASE_PRIVATE_KEY) {
      throw new Error('FIREBASE_PRIVATE_KEY non definita. Controlla il file .env');
    }

    const privateKey = process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');

    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: privateKey
      })
    });
    console.log('✅ Firebase Admin inizializzato');
  } catch (error) {
    console.error('❌ Errore inizializzazione Firebase:', error);
    process.exit(1);
  }
}

module.exports = admin;
