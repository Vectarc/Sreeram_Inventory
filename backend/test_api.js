const http = require('http');

http.get('http://localhost:5000/api/products/list/all-shops', (res) => {
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    console.log('Status Code:', res.statusCode);
    console.log('Body:', data);
    process.exit(0);
  });
}).on('error', (err) => {
  console.error('Error connecting to API server:', err.message);
  process.exit(1);
});
