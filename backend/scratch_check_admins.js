const { supabase } = require('./src/config/supabase');
require('dotenv').config();

async function checkAdmins() {
  const { data, error } = await supabase.from('admins').select('username');
  if (error) {
    console.error('Error fetching admins:', error);
    return;
  }
  console.log('Admin usernames:', data.map(a => a.username));
}

checkAdmins();
