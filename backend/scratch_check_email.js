 const mongoose = require('mongoose');
mongoose.connect('mongodb://localhost:27017/sreeram_db').then(async () => {
  const db = mongoose.connection.db;
  const branches = await db.collection('branches').find({ email: { $exists: true, $ne: '' } }).toArray();
  console.log('--- EMAIL RESULT ---');
  if (branches.length === 0) {
    console.log('No branches with an email were found in the database. The system cannot send the OTP.');
  } else {
    const main = branches.find(b => b.isMain && b.isActive);
    if (main) console.log('Mail was sent to Main Branch Email:', main.email);
    else console.log('Mail was sent to Fallback Branch Email:', branches[0].email);
  }
  console.log('--------------------');
  process.exit(0);
}).catch(err => {
  console.error('DB Error:', err);
  process.exit(1);
});
