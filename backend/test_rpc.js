const { supabase } = require('./src/config/supabase');

async function test() {
  try {
    const { data, error } = await supabase.rpc('exec_sql', { sql_query: 'ALTER TABLE contacts ADD COLUMN IF NOT EXISTS branch TEXT;' });
    console.log('exec_sql response:', { data, error });
  } catch (e) {
    console.error('Catch error:', e);
  }
  process.exit(0);
}

test();
