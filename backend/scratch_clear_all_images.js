require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
const BUCKET = 'products';

async function clearImages() {
  console.log('🚀 Starting bulk image removal...');

  // 1. Clear database references
  const { data: updated, error: dbError } = await supabase
    .from('products')
    .update({ image_url: null })
    .not('image_url', 'is', null) // Only update those that have an image
    .select();

  if (dbError) {
    console.error('❌ Error updating database:', dbError.message);
    return;
  }
  console.log(`✅ Cleared image URLs for ${updated.length} products in database.`);

  // 2. Clear storage bucket
  const { data: files, error: listError } = await supabase.storage
    .from(BUCKET)
    .list();

  if (listError) {
    console.error('❌ Error listing storage files:', listError.message);
    return;
  }

  if (files && files.length > 0) {
    const fileNames = files.map(f => f.name).filter(name => name !== '.emptyFolderPlaceholder');
    if (fileNames.length === 0) {
      console.log('ℹ️ No images found in storage to delete.');
      return;
    }

    console.log(`📦 Found ${fileNames.length} files in storage. Deleting...`);
    const { error: deleteError } = await supabase.storage
      .from(BUCKET)
      .remove(fileNames);

    if (deleteError) {
      console.error('❌ Error deleting storage files:', deleteError.message);
    } else {
      console.log('✅ Successfully wiped all images from Supabase Storage.');
    }
  } else {
    console.log('ℹ️ Storage bucket is already empty.');
  }

  console.log('✨ All done!');
}

clearImages();
