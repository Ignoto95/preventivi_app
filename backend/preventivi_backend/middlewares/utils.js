const pool = require('../config/db');

module.exports = {
  verifyDocumentAccess: async (userId, documentId) => {
    console.log(`🔐 Verifica accesso per user: ${userId}, documento: ${documentId}`);
    
    const connection = await pool.getConnection();
    try {
      // 1. PRIMA VERIFICA SE L'UTENTE È ADMIN
      const [adminCheck] = await connection.query(
        `SELECT 1 FROM user_roles WHERE user_id = ? AND role = 'admin'`,
        [userId]
      );
      
      if (adminCheck.length > 0) {
        console.log('✅ Utente è admin, accesso consentito');
        return true;
      }
      
      // 2. POI VERIFICA L'ACCESSO SPECIFICO NELLA TABELLA documenti_accessi
      const [rows] = await connection.query(
        `SELECT 1 FROM documenti_accessi
         WHERE user_id = ? AND document_id = ?`,
        [userId, documentId]
      );
      
      const hasAccess = rows.length > 0;
      console.log(`📊 Accesso ${hasAccess ? 'CONSENTITO' : 'NEGATO'} dalla tabella documenti_accessi`);
      return hasAccess;
      
    } catch (error) {
      console.error('❌ Errore in verifyDocumentAccess:', error);
      return false;
    } finally {
      connection.release();
    }
  }
};
