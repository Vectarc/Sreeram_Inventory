require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Supabase configuration missing from .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

const checkConnection = async () => {
  try {
    // A simple query to check the connection. 
    // Usually fetching from a non-existent table or an empty query works,
    // or just performing a simple healthcheck.
    const { data, error } = await supabase.from('admins').select('id').limit(1);
    if (error && error.code !== '42P01') { 
        // 42P01 is "relation does not exist", which just means table isn't created yet but connection is fine
        throw error;
    }
    console.log(`✅ MongoDB Connection Replaced: Successfully connected to Supabase PostgreSQL at ${supabaseUrl}`);
  } catch (err) {
    console.error('❌ Supabase Connection Error:', err.message);
  }
};

module.exports = { supabase, checkConnection };
