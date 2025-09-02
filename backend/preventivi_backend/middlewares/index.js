const { authenticateFirebase } = require('./firebase/auth');
const { authorizeRoles } = require('./roles');
const staticFiles = require('./static');
const { verifyDocumentAccess } = require('./utils');

module.exports = {
  authenticateFirebase,
  authorizeRoles,
  staticFiles,
  verifyDocumentAccess
};
