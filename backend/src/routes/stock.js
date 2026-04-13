const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { protect, adminOnly } = require('../middleware/auth');
 
const mapStockToFrontend = (s) => {
  if (!s) return null;
  const mapped = {
    ...s,
    _id: s.id,
    minLevel: s.min_level,
    productName: s.product_name,
    adjustmentAlerts: s.adjustment_alerts || []
  };
  if (s.product && typeof s.product === 'object') {
    mapped.product = {
      ...s.product,
      _id: s.product.id
    };
  }
  return mapped;
};

// ═══════════════════════════════════════════
// PUBLIC ROUTES — no login token needed
// ═══════════════════════════════════════════

// GET ALL STOCK LEVELS
router.get('/', async (req, res) => {
  try {
    let query = supabase.from('stocks').select('*, product:products(id, name, code, category, image_url)').order('product_name', { ascending: true });
    
    if (req.query.branch) query = query.eq('branch', req.query.branch);
    
    const { data: stocks, error } = await query;
    if (error) throw error;
    
    res.json({ success: true, count: stocks.length, stocks: stocks.map(mapStockToFrontend) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET LOW STOCK ALERTS
router.get('/alerts', async (req, res) => {
  try {
    const { data: all, error } = await supabase.from('stocks').select('*, product:products(id, name, code, category, image_url)');
    if (error) throw error;
    
    const alerts = all.filter(s =>
      (s.quantity <= s.min_level) ||
      (s.adjustment_alerts && s.adjustment_alerts.length > 0)
    );
    
    const enriched = alerts.map(s => {
      const obj = { ...s };
      const reasons = [];
      if (s.quantity <= s.min_level) reasons.push('Low Stock');

      const alertsArr = s.adjustment_alerts || [];
      obj.totalAdjustedQty = alertsArr.reduce((sum, a) => sum + (a.quantity || 0), 0);

      if (alertsArr.length > 0) {
        const adjustmentReasons = alertsArr.map(a => a.reason);
        adjustmentReasons.forEach(r => {
          if (!reasons.includes(r)) reasons.push(r);
        });

        const latest = alertsArr[alertsArr.length - 1];
        obj.latestAdjustReason = latest.reason || 'Adjustment';
        obj.latestAdjustNote = latest.note || '';
        obj.latestAdjustBy = latest.createdBy || '';
        obj.latestAdjustAt = latest.createdAt;
      }
      obj.reasons = reasons;
      return mapStockToFrontend(obj);
    });
    res.json({ success: true, count: enriched.length, alerts: enriched });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET ALL TRANSACTIONS
router.get('/transactions/all', async (req, res) => {
  try {
    let query = supabase.from('transactions').select('*, product:products(name, code)').order('created_at', { ascending: false }).limit(200);
    
    if (req.query.type) query = query.eq('type', req.query.type);
    if (req.query.branch) query = query.eq('branch', req.query.branch);
    
    const { data: txns, error } = await query;
    if (error) throw error;
    
    // map fields for frontend
    const mapped = txns.map(t => ({
      _id: t.id,
      ...t,
      createdAt: t.created_at,
      createdBy: t.created_by,
      productName: t.product_name,
      fromBranch: t.from_branch,
      toBranch: t.to_branch,
    }));
    
    res.json({ success: true, count: mapped.length, transactions: mapped });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ═══════════════════════════════════════════
// PROTECTED ROUTES — login token required
// ═══════════════════════════════════════════
router.use(protect);

// GET SINGLE STOCK ITEM
router.get('/:id', async (req, res) => {
  try {
    const { data: stock, error } = await supabase.from('stocks').select('*, product:products(id, name, code, category, image_url)').eq('id', req.params.id).maybeSingle();
    if (error) throw error;
    if (!stock) return res.status(404).json({ success: false, message: 'Stock item not found.' });
    
    res.json({ success: true, stock: mapStockToFrontend(stock) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// CREATE / INITIALIZE STOCK ENTRY
router.post('/', async (req, res) => {
  try {
    const { productId, branch, quantity = 0, minLevel = 10 } = req.body;
    if (!productId || !branch)
      return res.status(400).json({ success: false, message: 'productId and branch are required.' });

    const { data: product, error: pError } = await supabase.from('products').select('*').eq('id', productId).maybeSingle();
    if (pError) throw pError;
    if (!product) return res.status(404).json({ success: false, message: 'Product not found.' });

    const { data: exists, error: checkError } = await supabase.from('stocks').select('id').eq('product_id', productId).eq('branch', branch).maybeSingle();
    if (checkError) throw checkError;
    if (exists)
      return res.status(409).json({ success: false, message: 'Stock entry already exists for this product and branch.' });

    const { data: stock, error } = await supabase.from('stocks').insert([{
      product_id: productId,
      product_name: product.name,
      category: product.category,
      branch,
      quantity,
      unit: product.unit,
      min_level: minLevel,
      adjustment_alerts: []
    }]).select().single();

    if (error) throw error;
    
    res.status(201).json({ success: true, message: 'Stock entry created.', stock: mapStockToFrontend(stock) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// UPDATE MINIMUM STOCK LEVEL
router.put('/:id/minlevel', async (req, res) => {
  try {
    const { minLevel } = req.body;
    if (minLevel === undefined)
      return res.status(400).json({ success: false, message: 'minLevel is required.' });

    const { data: stock, error } = await supabase.from('stocks')
      .update({ min_level: minLevel, updated_at: new Date().toISOString() })
      .eq('id', req.params.id)
      .select().maybeSingle();
      
    if (error) throw error;
    if (!stock) return res.status(404).json({ success: false, message: 'Stock item not found.' });

    res.json({ success: true, message: 'Minimum level updated.', stock: mapStockToFrontend(stock) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE STOCK ENTRY (Admin only)
router.delete('/:id', adminOnly, async (req, res) => {
  try {
    const { data: stock, error } = await supabase.from('stocks').delete().eq('id', req.params.id).select().maybeSingle();
    if (error) throw error;
    if (!stock) return res.status(404).json({ success: false, message: 'Stock item not found.' });
    res.json({ success: true, message: 'Stock entry deleted.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// CREATE TRANSACTION (Purchase / Sale / Adjust / Transfer)
router.post('/transactions', async (req, res) => {
  try {
    const { type, productId, quantity, branch, fromBranch, toBranch, note = '', minLevel } = req.body;

    if (!type || !productId || !quantity)
      return res.status(400).json({ success: false, message: 'type, productId, and quantity are required.' });

    const { data: product, error: pError } = await supabase.from('products').select('*').eq('id', productId).maybeSingle();
    if (pError) throw pError;
    if (!product) return res.status(404).json({ success: false, message: 'Product not found.' });

    const qty = parseFloat(quantity);
    if (isNaN(qty) || qty <= 0)
      return res.status(400).json({ success: false, message: 'Quantity must be a positive number.' });

    let transactionData = {
      type,
      product_id: productId,
      product_name: product.name,
      quantity: qty,
      note,
      created_by: req.user.username,
    };

    if (type === 'purchase' || type === 'adjust') {
      if (!branch) return res.status(400).json({ success: false, message: 'branch is required for purchase/adjust.' });
      transactionData.branch = branch;

      let { data: stock, error: sError } = await supabase.from('stocks').select('*').eq('product_id', productId).eq('branch', branch).maybeSingle();
      if (sError) throw sError;
      
      let stockId;
      if (!stock) {
        const stockData = { 
          product_id: productId, 
          product_name: product.name, 
          category: product.category, 
          branch, 
          quantity: 0, 
          unit: product.unit,
          adjustment_alerts: []
        };
        if (type === 'purchase' && minLevel && minLevel > 0) {
          stockData.min_level = minLevel;
        }
        const { data: newStock, error: createStockErr } = await supabase.from('stocks').insert([stockData]).select().single();
        if (createStockErr) throw createStockErr;
        stock = newStock;
        stockId = stock.id;
      } else {
        stockId = stock.id;
      }

      let updatePayload = {};
      
      if (type === 'purchase') {
        updatePayload.quantity = parseFloat(stock.quantity) + qty;
        if (minLevel && minLevel > 0) updatePayload.min_level = minLevel;
        updatePayload.adjustment_alerts = []; // clear
      } else if (type === 'adjust') {
        if (stock.quantity < qty) {
          return res.status(400).json({
            success: false,
            message: `Cannot adjust more than available stock. Available: ${stock.quantity} ${product.unit}`,
          });
        }
        updatePayload.quantity = parseFloat(stock.quantity) - qty;
        const reasonPart = note.split(' — ')[0].trim() || 'Adjustment';
        const notePart = note.includes(' — ') ? note.split(' — ').slice(1).join(' — ').trim() : '';
        const alertsArr = stock.adjustment_alerts || [];
        alertsArr.push({
          reason: reasonPart,
          quantity: qty,
          note: notePart,
          createdBy: req.user.username,
          createdAt: new Date().toISOString(),
        });
        updatePayload.adjustment_alerts = alertsArr;
      }

      if (!stock.category) {
        updatePayload.category = product.category;
      }

      updatePayload.updated_at = new Date().toISOString();
      const { error: updErr } = await supabase.from('stocks').update(updatePayload).eq('id', stockId);
      if (updErr) throw updErr;

    } else if (type === 'sale') {
      if (!branch) return res.status(400).json({ success: false, message: 'branch is required for sale.' });
      transactionData.branch = branch;

      const { data: stock, error: sErr } = await supabase.from('stocks').select('*').eq('product_id', productId).eq('branch', branch).maybeSingle();
      if (sErr) throw sErr;
      if (!stock || stock.quantity < qty)
        return res.status(400).json({ success: false, message: `Insufficient stock. Available: ${stock?.quantity ?? 0} ${product.unit}` });

      const payload = { quantity: parseFloat(stock.quantity) - qty, updated_at: new Date().toISOString() };
      if (!stock.category) payload.category = product.category;
      
      const { error: updErr } = await supabase.from('stocks').update(payload).eq('id', stock.id);
      if (updErr) throw updErr;

    } else if (type === 'transfer') {
      if (!fromBranch || !toBranch)
        return res.status(400).json({ success: false, message: 'fromBranch and toBranch are required for transfer.' });
      transactionData.branch = `${fromBranch} → ${toBranch}`;
      transactionData.from_branch = fromBranch;
      transactionData.to_branch = toBranch;

      const { data: fromStock, error: fErr } = await supabase.from('stocks').select('*').eq('product_id', productId).eq('branch', fromBranch).maybeSingle();
      if (fErr) throw fErr;
      if (!fromStock || fromStock.quantity < qty)
        return res.status(400).json({ success: false, message: `Insufficient stock at ${fromBranch}. Available: ${fromStock?.quantity ?? 0} ${product.unit}` });

      const fromPayload = { quantity: parseFloat(fromStock.quantity) - qty, updated_at: new Date().toISOString() };
      if (!fromStock.category) fromPayload.category = product.category;
      await supabase.from('stocks').update(fromPayload).eq('id', fromStock.id);

      let { data: toStock, error: tErr } = await supabase.from('stocks').select('*').eq('product_id', productId).eq('branch', toBranch).maybeSingle();
      if (tErr) throw tErr;
      if (!toStock) {
        const { data: newStock, error: cErr } = await supabase.from('stocks').insert([{ 
          product_id: productId, 
          product_name: product.name, 
          category: product.category, 
          branch: toBranch, 
          quantity: qty, 
          unit: product.unit,
          adjustment_alerts: []
        }]).select().single();
        if (cErr) throw cErr;
      } else {
        const toPayload = { quantity: parseFloat(toStock.quantity) + qty, updated_at: new Date().toISOString() };
        if (!toStock.category) toPayload.category = product.category;
        await supabase.from('stocks').update(toPayload).eq('id', toStock.id);
      }
    }

    const { data: transaction, error: tErr } = await supabase.from('transactions').insert([transactionData]).select().single();
    if (tErr) throw tErr;
    
    res.status(201).json({ 
      success: true, 
      message: 'Transaction recorded.', 
      transaction: {
        ...transaction,
        _id: transaction.id,
        productName: transaction.product_name,
        fromBranch: transaction.from_branch,
        toBranch: transaction.to_branch,
        createdBy: transaction.created_by
      } 
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE TRANSACTION (Admin only)
router.delete('/transactions/:id', adminOnly, async (req, res) => {
  try {
    const { data: txn, error } = await supabase.from('transactions').delete().eq('id', req.params.id).select().maybeSingle();
    if (error) throw error;
    if (!txn) return res.status(404).json({ success: false, message: 'Transaction not found.' });
    res.json({ success: true, message: 'Transaction deleted.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;