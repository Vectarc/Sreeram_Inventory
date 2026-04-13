const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { protect, adminOnly } = require('../middleware/auth');

const mapVendorToDB = (body) => {
  const payload = { ...body };
  delete payload._id;
  delete payload.__v;
  return payload;
};

const mapVendorToFrontend = (vendor) => ({
  ...vendor,
  _id: vendor.id
});

// Get all vendors
router.get('/', protect, async (req, res) => {
  try {
    const { data: vendors, error } = await supabase.from('vendors').select('*').order('name');
    if (error) throw error;
    res.json({ success: true, vendors: vendors.map(mapVendorToFrontend) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Create vendor
router.post('/', protect, adminOnly, async (req, res) => {
  try {
    const payload = mapVendorToDB(req.body);
    const { data: vendor, error } = await supabase.from('vendors').insert([payload]).select().single();
    if (error) throw error;
    res.status(201).json({ success: true, vendor: mapVendorToFrontend(vendor) });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// Update vendor
router.put('/:id', protect, adminOnly, async (req, res) => {
  try {
    const payload = mapVendorToDB(req.body);
    const { data: vendor, error } = await supabase.from('vendors').update(payload).eq('id', req.params.id).select().single();
    if (error) throw error;
    if (!vendor) return res.status(404).json({ success: false, message: 'Vendor not found' });
    res.json({ success: true, vendor: mapVendorToFrontend(vendor) });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// Delete vendor
router.delete('/:id', protect, adminOnly, async (req, res) => {
  try {
    const { data: vendor, error } = await supabase.from('vendors').delete().eq('id', req.params.id).select().single();
    if (error) throw error;
    if (!vendor) return res.status(404).json({ success: false, message: 'Vendor not found' });
    res.json({ success: true, message: 'Vendor deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
