const { supabase } = require('./src/config/supabase');

async function test() {
  try {
    const { data: contacts, error: err1 } = await supabase.from('contacts').select('branch').limit(1);
    console.log('Contacts branch query:', { data: contacts, error: err1 });
    
    const { data: vendors, error: err2 } = await supabase.from('vendors').select('branch').limit(1);
    console.log('Vendors branch query:', { data: vendors, error: err2 });
  } catch (e) {
    console.error('Catch error:', e);
  }
  process.exit(0);
}

test();
