const { supabase } = require('./src/config/supabase');

async function run() {
  try {
    const { data: products, error } = await supabase
      .from('products')
      .select('id, name, code, category, branch')
      .eq('branch', 'SREE RAM DYES & CHEMICALS');
    if (error) throw error;
    console.log('PRODUCTS IN SREE RAM DYES & CHEMICALS:');
    console.log(products);
  } catch (err) {
    console.error(err);
  }
  process.exit(0);
}

run();
