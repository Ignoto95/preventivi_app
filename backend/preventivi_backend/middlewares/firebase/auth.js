const admin = require('./admin');
const pool = require('../../config/db');

module.exports = {
  authenticateFirebase: async (req, res, next) => {
    let idToken;

    // 1. Cerca il token negli headers (Bearer token)
    const authHeader = req.headers.authorization;
    if (authHeader?.startsWith('Bearer ')) {
      idToken = authHeader.split(' ')[1];
    } 
    // 2. Cerca il token nei query parameters
    else if (req.query.token) {
      idToken = req.query.token;
    }

    if (!idToken) {
      return res.status(401).json({
        error: 'Token non fornito',
        code: 'MISSING_AUTH_TOKEN'
      });
    }

    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);

      // Verifica email (opzionale)
      if (process.env.REQUIRE_EMAIL_VERIFICATION === 'true' && !decodedToken.email_verified) {
        return res.status(403).json({
          error: 'Email non verificata',
          code: 'EMAIL_NOT_VERIFIED'
        });
      }

      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        role: decodedToken.role || 'user',
        email_verified: decodedToken.email_verified || false
      };

      next();
    } catch (error) {
      console.error('Errore verifica token:', error.message);

      const statusCode = error.code === 'auth/id-token-expired' ? 401 : 403;
      res.status(statusCode).json({
        error: 'Accesso non autorizzato',
        code: error.code || 'AUTH_ERROR',
        details: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
};
