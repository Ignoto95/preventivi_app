const jwt = require('jsonwebtoken');
const pool = require('../config/db');

module.exports = {
  verifyToken: (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1];
    
    if (!token) {
      return res.status(403).json({ error: 'Token non fornito' });
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: 'Token non valido' });
      }
      req.userId = decoded.id;
      next();
    });
  },

  isAdmin: async (req, res, next) => {
    const connection = await pool.getConnection();
    try {
      const [rows] = await connection.query(
        'SELECT ruolo FROM Utenti WHERE id = ?',
        [req.userId]
      );
      
      if (rows[0]?.ruolo !== 'admin') {
        return res.status(403).json({ error: 'Accesso negato' });
      }
      next();
    } catch (error) {
      res.status(500).json({ error: 'Errore del server' });
    } finally {
      connection.release();
    }
  }
};
