const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { protect, adminOnly } = require('../middleware/auth');

// GET ALL UNITS
router.get('/', async (req, res) => {
  try {
    const { data: units, error } = await supabase.from('units').select('*').order('name');
    if (error) throw error;
    res.json({ success: true, count: units.length, units: units.map(u => ({ ...u, _id: u.id })) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// CREATE UNIT (admin only)
router.post('/', protect, adminOnly, async (req, res) => {
  try {
    const { name } = req.body;
    if (!name) return res.status(400).json({ success: false, message: 'Unit name is required.' });

    const { data: exists, error: checkError } = await supabase.from('units').select('id').ilike('name', name).maybeSingle();
    if (checkError) throw checkError;
    if (exists) return res.status(409).json({ success: false, message: 'Unit already exists.' });

    const { data: unit, error } = await supabase.from('units').insert([{ name: name.toUpperCase() }]).select().single();
    if (error) throw error;
    res.status(201).json({ success: true, message: 'Unit created.', unit: { ...unit, _id: unit.id } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE UNIT (admin only)
router.post('/delete', protect, adminOnly, async (req, res) => {
  try {
    const { name } = req.body;
    if (!name) return res.status(400).json({ success: false, message: 'Unit name is required.' });

    const { data: unit, error } = await supabase.from('units').delete().ilike('name', name).select().maybeSingle();
    if (error) throw error;
    if (!unit) return res.status(404).json({ success: false, message: 'Unit not found.' });

    res.json({ success: true, message: 'Unit deleted.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
