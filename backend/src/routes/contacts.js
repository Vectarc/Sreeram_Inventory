const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { protect, adminOnly } = require('../middleware/auth');

const mapContactToFrontend = (c) => ({
  ...c,
  isActive: c.is_active,
  _id: c.id
});

// ═══════════════════════════════════════════
// PUBLIC ROUTES — no login token needed
// ═══════════════════════════════════════════

// GET ALL CONTACTS
router.get('/', async (req, res) => {
  try {
    let query = supabase.from('contacts').select('*').order('category').order('name');
    if (req.query.category) query = query.eq('category', req.query.category);
    
    const { data: contacts, error } = await query;
    if (error) throw error;
    res.json({ success: true, count: contacts.length, contacts: contacts.map(mapContactToFrontend) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET SINGLE CONTACT
router.get('/:id', async (req, res) => {
  try {
    const { data: contact, error } = await supabase.from('contacts').select('*').eq('id', req.params.id).maybeSingle();
    if (error) throw error;
    if (!contact) return res.status(404).json({ success: false, message: 'Contact not found.' });
    res.json({ success: true, contact: mapContactToFrontend(contact) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ═══════════════════════════════════════════
// PROTECTED ROUTES — login token required
// ═══════════════════════════════════════════
router.use(protect);

// CREATE CONTACT
router.post('/', async (req, res) => {
  try {
    const { name, role, phone, email, category, description } = req.body;
    if (!name || !phone || !category)
      return res.status(400).json({ success: false, message: 'name, phone, and category are required.' });
    
    const { data: contact, error } = await supabase.from('contacts').insert([{ name, role, phone, email, category, description }]).select().single();
    if (error) throw error;
    res.status(201).json({ success: true, message: 'Contact created.', contact: mapContactToFrontend(contact) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// UPDATE CONTACT
router.put('/:id', async (req, res) => {
  try {
    const updateData = {};
    const { name, role, phone, email, category, description, isActive } = req.body;
    if (name !== undefined) updateData.name = name;
    if (role !== undefined) updateData.role = role;
    if (phone !== undefined) updateData.phone = phone;
    if (email !== undefined) updateData.email = email;
    if (category !== undefined) updateData.category = category;
    if (description !== undefined) updateData.description = description;
    if (isActive !== undefined) updateData.is_active = isActive;
    
    const { data: contact, error } = await supabase.from('contacts').update(updateData).eq('id', req.params.id).select().maybeSingle();
    if (error) throw error;
    if (!contact) return res.status(404).json({ success: false, message: 'Contact not found.' });
    
    res.json({ success: true, message: 'Contact updated.', contact: mapContactToFrontend(contact) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE CONTACT (Admin only)
router.delete('/:id', adminOnly, async (req, res) => {
  try {
    const { data: contact, error } = await supabase.from('contacts').delete().eq('id', req.params.id).select().maybeSingle();
    if (error) throw error;
    if (!contact) return res.status(404).json({ success: false, message: 'Contact not found.' });
    res.json({ success: true, message: 'Contact deleted.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;