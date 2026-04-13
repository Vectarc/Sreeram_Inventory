const bcrypt = require('bcryptjs');
const { supabase } = require('./src/config/supabase'); // make sure path is correct

async function resetPassword() {
  try {
    console.log('Generating correct hash for Sree@123...');
    const newHash = await bcrypt.hash('Sree@123', 10);
    
    console.log('Updating Supabase...');
    const { error } = await supabase
      .from('admins')
      .update({ password: newHash })
      .eq('username', 'Sreeram');
      
    if (error) {
      console.error('Failed to update:', error.message);
    } else {
      console.log('✅ Admin password successfully fixed to Sree@123 in Supabase!');
    }
  } catch (err) {
    console.error('Error:', err);
  }
}

resetPassword();
