const path = require('path');

try {
  console.log('Requiring middleware/auth...');
  const auth = require('./backend/src/middleware/auth');
  console.log('SUCCESS: auth is', typeof auth, 'keys:', Object.keys(auth));
  console.log('protect is', typeof auth.protect);
  console.log('adminOnly is', typeof auth.adminOnly);
} catch (err) {
  console.error('FAILED middleware/auth:');
  console.error(err);
}
