const { supabase } = require('./src/config/supabase');

async function test() {
  try {
    const { data: contacts, error: err1 } = await supabase.from('contacts').select('*').limit(1);
    console.log('Contacts keys:', contacts && contacts.length > 0 ? Object.keys(contacts[0]) : 'no data', { error: err1 });
    if (contacts && contacts.length > 0) {
      console.log('Contacts sample:', contacts[0]);
    }
    
    const { data: vendors, error: err2 } = await supabase.from('vendors').select('*').limit(1);
    console.log('Vendors keys:', vendors && vendors.length > 0 ? Object.keys(vendors[0]) : 'no data', { error: err2 });
    if (vendors && vendors.length > 0) {
      console.log('Vendors sample:', vendors[0]);
    }
  } catch (e) {
    console.error('Catch error:', e);
  }
  process.exit(0);
}

test();
