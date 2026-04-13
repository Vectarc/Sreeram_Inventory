const fs = require('fs');
const path = require('path');

const files = [
  './routes/auth',
  './routes/products',
  './routes/stock',
  './routes/contacts',
  './routes/branches',
  './routes/vendors'
];

process.chdir(path.join(__dirname, 'backend', 'src'));

files.forEach(file => {
  try {
    console.log(`Requiring ${file}...`);
    require(file);
    console.log(`Successfully required ${file}`);
  } catch (err) {
    console.error(`FAILED to require ${file}:`);
    console.error(err);
  }
});
