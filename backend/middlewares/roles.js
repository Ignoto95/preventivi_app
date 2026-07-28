const ROLES = {
  ADMIN: 'admin',
  TECHNICIAN: 'technician',
  USER: 'user'
};

// Lista degli UID degli admin (sostituisci con i tuoi UID)
const ADMIN_UIDS = [
  'cpAq4pxuU1YU0fgi3Wzzr500dkq2',
  'eFuKQQ1ZtngUcVpjJ5Bo575WPdA3'
];

const authorizeRoles = (allowedRoles) => (req, res, next) => {
  try {
    // Se la route richiede admin e l'utente è nella lista admin, passa
    if (allowedRoles.includes(ROLES.ADMIN) && ADMIN_UIDS.includes(req.user.uid)) {
      return next();
    }

    if (allowedRoles.includes(ROLES.TECHNICIAN) && req.user.role === ROLES.TECHNICIAN) {
      return next();
    }

    if (allowedRoles.includes(ROLES.USER) && req.user.role === ROLES.USER) {
      return next();
    }

    // Se nessun ruolo corrisponde ma la funzione è arrivata fin qui
    res.status(403).json({ error: 'Ruolo non autorizzato' });
  } catch (error) {
    console.error('Errore controllo ruoli:', error);
    res.status(500).json({ error: 'Errore interno del server' });
  }
};

module.exports = { authorizeRoles, ROLES };
