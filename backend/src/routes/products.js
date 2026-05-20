const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { protect, adminOnly } = require('../middleware/auth');
const multer = require('multer');
const path = require('path');

// Configure multer to use memory storage (we'll upload directly to Supabase)
const upload = multer({ storage: multer.memoryStorage() });
const STORAGE_BUCKET = 'products';

// Helper to delete image from Supabase Storage
const deleteImageFromSupabase = async (url) => {
  if (!url || !url.includes(STORAGE_BUCKET)) return;
  try {
    // Extract file path after "products/"
    const parts = url.split(`${STORAGE_BUCKET}/`);
    if (parts.length < 2) return;
    const filePath = parts[1];
    
    const { error } = await supabase.storage.from(STORAGE_BUCKET).remove([filePath]);
    if (error) console.error('Error deleting image from Supabase:', error.message);
  } catch (err) {
    console.error('Catch error deleting image:', err.message);
  }
};

const mapProductToFrontend = (p) => {
  if (!p) return null;
  return {
    ...p,
    isActive: p.is_active,
    imageUrl: p.image_url,
    _id: p.id,
    createdAt: p.created_at,
    updatedAt: p.updated_at,
    createdBy: p.created_by,
    branch: p.branch
  };
};

// ═══════════════════════════════════════════
// PUBLIC ROUTES — no login token needed
// ═══════════════════════════════════════════

// GET ALL ACTIVE PRODUCTS (public — only isActive:true shown)
router.get('/', async (req, res) => {
  try {
    let query = supabase.from('products').select('*').order('created_at', { ascending: false });
    if (req.query.category) query = query.eq('category', req.query.category);
    if (req.query.branch) query = query.eq('branch', req.query.branch);
    
    // If no token → only show active products
    if (req.query.isActive !== undefined) {
      const isActive = req.query.isActive === 'true';
      query = query.eq('is_active', isActive);
    }
    
    const { data: products, error } = await query;
    if (error) throw error;
    
    res.json({ success: true, count: products.length, products: products.map(mapProductToFrontend) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET PRODUCTS WITH STOCK INFO (all shops) — must be BEFORE /:id
router.get('/list/all-shops', async (req, res) => {
  try {
    let query = supabase.from('stocks').select('*, product:products(*)');
    if (req.query.branch) query = query.eq('branch', req.query.branch);
    
    const { data: stocks, error } = await query;
    if (error) throw error;
    
    const result = stocks.map(s => ({
      _id: s.product_id,
      name: s.product_name,
      code: s.product?.code,
      unit: s.unit,
      category: s.product?.category,
      brand: s.product?.brand || '',
      vendor: s.product?.vendor || '',
      shop: s.branch,
      quantity: s.quantity,
      imageUrl: s.product?.image_url,
      adjustmentAlerts: s.adjustment_alerts || [], 
    }));
    res.json({ success: true, count: result.length, products: result });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET SINGLE PRODUCT
router.get('/:id', async (req, res) => {
  try {
    const { data: product, error } = await supabase.from('products').select('*').eq('id', req.params.id).maybeSingle();
    if (error) throw error;
    if (!product) return res.status(404).json({ success: false, message: 'Product not found.' });
    
    res.json({ success: true, product: mapProductToFrontend(product) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ═══════════════════════════════════════════
// PROTECTED ROUTES — login token required
// ═══════════════════════════════════════════
router.use(protect);

// CREATE PRODUCT (admin only)
router.post('/', adminOnly, upload.single('image'), async (req, res) => {
  try {
    const { name, code, unit, category, branch, brand, vendor, description } = req.body;
    if (!name || !code || !unit || !category || !branch)
      return res.status(400).json({ success: false, message: 'name, code, unit, category, and branch are required.' });
    
    const { data: exists, error: checkError } = await supabase.from('products').select('id').ilike('code', code).eq('branch', branch).maybeSingle();
    if (checkError) throw checkError;
    if (exists) return res.status(409).json({ success: false, message: 'Product code already exists in this branch.' });

    let imageUrl = null;
    if (req.file) {
      const fileName = `${Date.now()}-${req.file.originalname.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from(STORAGE_BUCKET)
        .upload(fileName, req.file.buffer, {
          contentType: req.file.mimetype,
          cacheControl: '3600'
        });

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabase.storage
        .from(STORAGE_BUCKET)
        .getPublicUrl(fileName);
      
      imageUrl = publicUrl;
    }

    const { data: product, error } = await supabase.from('products').insert([{
      name,
      code: code.toUpperCase(),
      unit,
      category,
      branch,
      brand: brand || '',
      vendor: (vendor === 'null' || !vendor) ? '' : vendor,
      description: description || '',
      image_url: imageUrl,
      created_by: req.user.username
    }]).select().single();
    
    if (error) throw error;
    res.status(201).json({ success: true, message: 'Product created.', product: mapProductToFrontend(product) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// UPDATE PRODUCT (admin only)
router.put('/:id', adminOnly, upload.single('image'), async (req, res) => {
  try {
    const updateData = {};
    const { name, code, unit, category, branch, brand, isActive, vendor, description, removeImage } = req.body;
    
    // Fetch current product to handle old image deletion
    const { data: current, error: getError } = await supabase.from('products').select('*').eq('id', req.params.id).maybeSingle();
    if (getError) throw getError;
    if (!current) return res.status(404).json({ success: false, message: 'Product not found.' });

    if (name !== undefined) updateData.name = name;
    if (code !== undefined) updateData.code = code.toUpperCase();
    if (unit !== undefined) updateData.unit = unit;
    if (category !== undefined) updateData.category = category;
    if (branch !== undefined) updateData.branch = branch;
    if (isActive !== undefined) updateData.is_active = isActive === 'true' || isActive === true;
    if (vendor !== undefined) {
      updateData.vendor = (vendor === 'null' || !vendor) ? '' : vendor;
    }
    if (brand !== undefined) updateData.brand = brand;
    if (description !== undefined) updateData.description = description;

    if (removeImage === 'true' || removeImage === true) {
      if (current.image_url) {
        await deleteImageFromSupabase(current.image_url);
      }
      updateData.image_url = null;
    } else if (req.file) {
      // Delete old image if it exists
      if (current.image_url) {
        await deleteImageFromSupabase(current.image_url);
      }

      const fileName = `${Date.now()}-${req.file.originalname.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from(STORAGE_BUCKET)
        .upload(fileName, req.file.buffer, {
          contentType: req.file.mimetype,
          cacheControl: '3600'
        });

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabase.storage
        .from(STORAGE_BUCKET)
        .getPublicUrl(fileName);
      
      updateData.image_url = publicUrl;
    }
    updateData.updated_at = new Date().toISOString();

    const { data: product, error } = await supabase.from('products').update(updateData).eq('id', req.params.id).select().maybeSingle();
    if (error) throw error;
    
    res.json({ success: true, message: 'Product updated.', product: mapProductToFrontend(product) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// TOGGLE ACTIVE STATUS (admin only)
router.patch('/:id/toggle', adminOnly, async (req, res) => {
  try {
    const { data: current, error: getError } = await supabase.from('products').select('is_active').eq('id', req.params.id).maybeSingle();
    if (getError) throw getError;
    if (!current) return res.status(404).json({ success: false, message: 'Product not found.' });
    
    const { data: product, error } = await supabase.from('products').update({ 
      is_active: !current.is_active,
      updated_at: new Date().toISOString()
    }).eq('id', req.params.id).select().maybeSingle();
    
    if (error) throw error;
    res.json({ success: true, message: `Product ${product.is_active ? 'activated' : 'deactivated'}.`, product: mapProductToFrontend(product) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE PRODUCT (admin only)
router.delete('/:id', adminOnly, async (req, res) => {
  try {
    // Fetch product to delete its image first
    const { data: current, error: getError } = await supabase.from('products').select('*').eq('id', req.params.id).maybeSingle();
    if (getError) throw getError;
    if (!current) return res.status(404).json({ success: false, message: 'Product not found.' });

    if (current.image_url) {
      await deleteImageFromSupabase(current.image_url);
    }

    const { error: deleteError } = await supabase.from('products').delete().eq('id', req.params.id);
    if (deleteError) throw deleteError;

    res.json({ success: true, message: 'Product deleted.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
module.exports = router;