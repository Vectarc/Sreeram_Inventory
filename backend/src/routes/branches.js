const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { protect, adminOnly } = require('../middleware/auth');

const mapBranchToDB = (body) => {
  const payload = { ...body };
  if (payload.isMain !== undefined) {
    payload.is_main = payload.isMain;
    delete payload.isMain;
  }
  if (payload.isActive !== undefined) {
    payload.is_active = payload.isActive;
    delete payload.isActive;
  }
  // Remove MongoDB specific stuff if the frontend sends it
  delete payload._id;
  delete payload.__v;
  return payload;
};

const mapBranchToFrontend = (b) => ({
  ...b,
  isMain: b.is_main,
  isActive: b.is_active,
  _id: b.id
});

// Get all branches - PUBLIC (for Home Page)
router.get('/public', async (req, res) => {
  try {
    const { data: branches, error } = await supabase.from('branches').select('*').eq('is_active', true).order('is_main', { ascending: false }).order('name');
    if (error) throw error;
    res.json({ success: true, branches: branches.map(mapBranchToFrontend) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Get all branches (protected)
router.get('/', protect, async (req, res) => {
  try {
    const { data: branches, error } = await supabase.from('branches').select('*').order('name');
    if (error) throw error;
    res.json({ success: true, branches: branches.map(mapBranchToFrontend) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Create branch
router.post('/', protect, adminOnly, async (req, res) => {
  try {
    const payload = mapBranchToDB(req.body);
    const { data: branch, error } = await supabase.from('branches').insert([payload]).select().single();
    if (error) throw error;
    res.status(201).json({ success: true, branch: mapBranchToFrontend(branch) });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// Update branch
router.put('/:id', protect, adminOnly, async (req, res) => {
  try {
    const payload = mapBranchToDB(req.body);
    
    // Fetch old branch name to check for name changes
    const { data: oldBranch, error: fetchErr } = await supabase
      .from('branches')
      .select('name')
      .eq('id', req.params.id)
      .maybeSingle();

    if (fetchErr) throw fetchErr;
    if (!oldBranch) return res.status(404).json({ success: false, message: 'Branch not found' });

    // Update branch
    const { data: branch, error } = await supabase
      .from('branches')
      .update(payload)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;
    if (!branch) return res.status(404).json({ success: false, message: 'Branch not found' });

    // If branch name changed, propagate to all other tables
    const oldName = oldBranch.name;
    const newName = branch.name;
    if (oldName && newName && oldName !== newName) {
      await Promise.all([
        supabase.from('users').update({ branch: newName }).eq('branch', oldName),
        supabase.from('products').update({ branch: newName }).eq('branch', oldName),
        supabase.from('stocks').update({ branch: newName }).eq('branch', oldName),
        supabase.from('login_history').update({ branch: newName }).eq('branch', oldName),
        supabase.from('transactions').update({ branch: newName }).eq('branch', oldName),
        supabase.from('transactions').update({ from_branch: newName }).eq('from_branch', oldName),
        supabase.from('transactions').update({ to_branch: newName }).eq('to_branch', oldName),
        supabase.from('contacts').update({ branch: newName }).eq('branch', oldName),
        supabase.from('vendors').update({ branch: newName }).eq('branch', oldName),
      ]);

      // Propagate transfers branch strings (e.g. 'Old Branch → Another Branch')
      try {
        const { data: transfers } = await supabase
          .from('transactions')
          .select('id, branch')
          .eq('type', 'transfer');

        if (transfers && transfers.length > 0) {
          for (const tx of transfers) {
            if (tx.branch && tx.branch.includes(oldName)) {
              const updatedBranchStr = tx.branch.replace(new RegExp(oldName, 'g'), newName);
              await supabase
                .from('transactions')
                .update({ branch: updatedBranchStr })
                .eq('id', tx.id);
            }
          }
        }
      } catch (txErr) {
        console.error('⚠️ Failed to propagate transaction transfer name updates:', txErr.message);
      }
    }

    res.json({ success: true, branch: mapBranchToFrontend(branch) });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// Delete branch
router.delete('/:id', protect, adminOnly, async (req, res) => {
  try {
    const { data: branch, error } = await supabase.from('branches').delete().eq('id', req.params.id).select().single();
    if (error) throw error;
    if (!branch) return res.status(404).json({ success: false, message: 'Branch not found' });
    res.json({ success: true, message: 'Branch deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
