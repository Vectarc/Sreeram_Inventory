const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { supabase } = require('../config/supabase');
const bcrypt = require('bcryptjs');
const { protect, adminOnly } = require('../middleware/auth');
const { sendOtpEmail } = require('../config/emailService');

const generateToken = (payload) => {
  return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' });
};

const mapUserToFrontend = (user) => {
  if (!user) return null;
  return {
    ...user,
    _id: user.id,
    isActive: user.is_active,
    displayPassword: user.display_password,
    branch: user.branch
  };
};

// ─────────────────────────────────────────
// ADMIN LOGIN
// POST /api/auth/admin/login
// ─────────────────────────────────────────
router.post('/admin/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password)
      return res.status(400).json({ success: false, message: 'Username and password are required.' });

    const { data: admin, error } = await supabase.from('admins').select('*').eq('username', username).maybeSingle();
    if (error) throw error;
    if (!admin)
      return res.status(401).json({ success: false, message: 'Invalid admin credentials.' });

    const isMatch = await bcrypt.compare(password, admin.password);
    if (!isMatch)
      return res.status(401).json({ success: false, message: 'Invalid admin credentials.' });

    const token = generateToken({ id: admin.id, username: admin.username, role: admin.role });

    res.json({
      success: true,
      message: 'Admin login successful.',
      token,
      user: { _id: admin.id, username: admin.username, role: admin.role },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────
// USER SIGN UP (Admin only creates user)
// ─────────────────────────────────────────
router.post('/user/signup', protect, adminOnly, async (req, res) => {
  try {
    const { username, password, branch } = req.body;
    if (!username || !password || !branch)
      return res.status(400).json({ success: false, message: 'Username, password, and branch are required.' });

    if (password.length < 6)
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters.' });

    const { data: exists, error: checkError } = await supabase.from('users').select('id').eq('username', username).maybeSingle();
    if (checkError) throw checkError;
    if (exists)
      return res.status(409).json({ success: false, message: 'Username already taken.' });

    const hashedPassword = await bcrypt.hash(password, 10);
    const { data: user, error } = await supabase.from('users').insert([{ 
      username, 
      password: hashedPassword,
      display_password: password,
      branch
    }]).select().single();
    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Account created successfully. You can now sign in.',
      user: mapUserToFrontend(user),
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────
// USER LOGIN
// ─────────────────────────────────────────
router.post('/user/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password)
      return res.status(400).json({ success: false, message: 'Username and password are required.' });

    const { data: user, error } = await supabase.from('users').select('*').eq('username', username).maybeSingle();
    if (error) throw error;
    
    if (!user)
      return res.status(401).json({ success: false, message: 'Account not found. Please sign up first.' });

    if (!user.is_active)
      return res.status(403).json({ success: false, message: 'Account is inactive. Contact admin.' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch)
      return res.status(401).json({ success: false, message: 'Incorrect password.' });

    const token = generateToken({ id: user.id, username: user.username, role: 'user', branch: user.branch });

    res.json({
      success: true,
      message: 'Login successful.',
      token,
      user: mapUserToFrontend(user),
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────
// GET ALL USERS (Admin only)
// ─────────────────────────────────────────
router.get('/users', protect, adminOnly, async (req, res) => {
  try {
    const { data: users, error } = await supabase.from('users').select('*').order('created_at', { ascending: false });
    if (error) throw error;
    
    res.json({ success: true, count: users.length, users: users.map(mapUserToFrontend) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────
// TOGGLE USER ACTIVE STATUS (Admin only)
// ─────────────────────────────────────────
router.put('/users/:id/toggle', protect, adminOnly, async (req, res) => {
  try {
    const { data: user, error: fetchErr } = await supabase.from('users').select('is_active').eq('id', req.params.id).maybeSingle();
    if (fetchErr) throw fetchErr;
    if (!user) return res.status(404).json({ success: false, message: 'User not found.' });

    const { data: updated, error } = await supabase.from('users').update({ is_active: !user.is_active }).eq('id', req.params.id).select().single();
    if (error) throw error;

    res.json({ success: true, message: `User ${updated.is_active ? 'activated' : 'deactivated'}.`, user: mapUserToFrontend(updated) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────
// DELETE USER (Admin only)
// ─────────────────────────────────────────
router.delete('/users/:id', protect, adminOnly, async (req, res) => {
  try {
    const { data: user, error } = await supabase.from('users').delete().eq('id', req.params.id).select().maybeSingle();
    if (error) throw error;
    if (!user) return res.status(404).json({ success: false, message: 'User not found.' });
    res.json({ success: true, message: 'User deleted successfully.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────
// REVEAL USER PASSWORD (Admin only + Admin Password Verify)
// ─────────────────────────────────────────
router.post('/users/:id/reveal', protect, adminOnly, async (req, res) => {
  try {
    const { adminPassword } = req.body;
    if (!adminPassword) return res.status(400).json({ success: false, message: 'Admin password required.' });

    const { data: admin, error: adminErr } = await supabase.from('admins').select('password').eq('id', req.user.id).maybeSingle();
    if (adminErr) throw adminErr;
    
    const isMatch = await bcrypt.compare(adminPassword, admin.password);
    if (!isMatch) return res.status(401).json({ success: false, message: 'Incorrect admin password.' });

    const { data: user, error: userErr } = await supabase.from('users').select('display_password').eq('id', req.params.id).maybeSingle();
    if (userErr) throw userErr;
    if (!user) return res.status(404).json({ success: false, message: 'User not found.' });

    res.json({ success: true, displayPassword: user.display_password || 'Password not available', password: user.display_password });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────
// CHANGE USER PASSWORD (Admin only)
// ─────────────────────────────────────────
router.post('/users/:id/change-password', protect, adminOnly, async (req, res) => {
  try {
    const { newPassword } = req.body;
    if (!newPassword || newPassword.length < 6)
      return res.status(400).json({ success: false, message: 'New password min 6 chars required.' });

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    const { error } = await supabase.from('users').update({ 
      password: hashedPassword,
      display_password: newPassword
    }).eq('id', req.params.id);
    
    if (error) throw error;
    res.json({ success: true, message: 'User password updated.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────
// CHANGE ADMIN PASSWORD
// ─────────────────────────────────────────
router.post('/admin/change-password', protect, adminOnly, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword)
      return res.status(400).json({ success: false, message: 'Current and new passwords required.' });

    const { data: admin, error: adminErr } = await supabase.from('admins').select('*').eq('id', req.user.id).maybeSingle();
    if (adminErr) throw adminErr;

    const isMatch = await bcrypt.compare(currentPassword, admin.password);
    if (!isMatch) return res.status(401).json({ success: false, message: 'Incorrect current password.' });

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    const { error } = await supabase.from('admins').update({ password: hashedPassword }).eq('id', req.user.id);
    if (error) throw error;

    res.json({ success: true, message: 'Admin password updated.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────
// ADMIN FORGOT PASSWORD — SEND OTP
// ─────────────────────────────────────────
router.post('/admin/forgot-password', async (req, res) => {
  try {
    const { data: admin, error: adminErr } = await supabase.from('admins').select('*').limit(1).maybeSingle();
    if (adminErr) throw adminErr;
    if (!admin)
      return res.status(404).json({ success: false, message: 'No admin account found.' });

    const { data: mainBranch, error: bErr } = await supabase.from('branches').select('name, email').eq('is_main', true).eq('is_active', true).maybeSingle();
    let targetEmail, targetName;
    
    if (mainBranch && mainBranch.email) {
      targetEmail = mainBranch.email;
      targetName = mainBranch.name;
    } else {
      const { data: anyBranch, error: aErr } = await supabase.from('branches').select('name, email').not('email', 'is', null).neq('email', '').limit(1).maybeSingle();
      if (!anyBranch || !anyBranch.email) {
        return res.status(400).json({
          success: false,
          message: 'No branch email found. Please add a branch with a valid email address first (Branch Management).',
        });
      }
      targetEmail = anyBranch.email;
      targetName = anyBranch.name;
    }

    const otp = crypto.randomInt(100000, 999999).toString();
    const expiryMinutes = 2;
    const otpExpiry = new Date(Date.now() + expiryMinutes * 60 * 1000).toISOString();

    const hashedOtp = await bcrypt.hash(otp, 6);
    const { error: updErr } = await supabase.from('admins').update({
      otp_code: hashedOtp,
      otp_expiry: otpExpiry,
      otp_attempts: 0
    }).eq('id', admin.id);
    if (updErr) throw updErr;

    const emailResult = await sendOtpEmail({
      toEmail: targetEmail,
      toName: targetName,
      otp,
      expiryMinutes,
    });

    if (!emailResult.success && !emailResult.devMode) {
      return res.status(500).json({
        success: false,
        message: `Failed to send OTP email: ${emailResult.message}. Check your EMAIL_USER and EMAIL_PASS in .env`,
      });
    }

    if (emailResult.devMode) {
      return res.json({
        success: true,
        message: `⚠️ Email not configured (dev mode). Check server configuration.`,
        devOtp: otp,
        sentTo: targetEmail,
      });
    }

    res.json({
      success: true,
      message: `OTP sent to root branch email (${targetEmail.replace(/(.{2})(.*)(@.*)/, '$1***$3')}).`,
      sentTo: targetEmail.replace(/(.{2})(.*)(@.*)/, '$1***$3'),
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────
// ADMIN RESET PASSWORD WITH OTP
// ─────────────────────────────────────────
router.post('/admin/reset-password-otp', async (req, res) => {
  try {
    const { otp, newPassword } = req.body;

    if (!otp || !newPassword)
      return res.status(400).json({ success: false, message: 'OTP and new password are required.' });

    if (newPassword.length < 6)
      return res.status(400).json({ success: false, message: 'New password must be at least 6 characters.' });

    const { data: admin, error: aErr } = await supabase.from('admins').select('*').limit(1).maybeSingle();
    if (aErr) throw aErr;
    if (!admin)
      return res.status(404).json({ success: false, message: 'Admin account not found.' });

    if (!admin.otp_code || !admin.otp_expiry)
      return res.status(400).json({ success: false, message: 'No OTP was requested. Please request a new OTP first.' });

    if (new Date() > new Date(admin.otp_expiry)) {
      await supabase.from('admins').update({ otp_code: null, otp_expiry: null, otp_attempts: 0 }).eq('id', admin.id);
      return res.status(400).json({ success: false, message: 'OTP has expired. Please request a new OTP.' });
    }

    if (admin.otp_attempts >= 5) {
      await supabase.from('admins').update({ otp_code: null, otp_expiry: null, otp_attempts: 0 }).eq('id', admin.id);
      return res.status(400).json({ success: false, message: 'Too many failed attempts. OTP invalidated.' });
    }

    const isOtpValid = await bcrypt.compare(otp, admin.otp_code);
    if (!isOtpValid) {
      const attempts = (admin.otp_attempts || 0) + 1;
      await supabase.from('admins').update({ otp_attempts: attempts }).eq('id', admin.id);
      const attemptsLeft = 5 - attempts;
      return res.status(400).json({
        success: false,
        message: `Invalid OTP. ${attemptsLeft > 0 ? attemptsLeft + ' attempt(s) remaining.' : 'OTP invalidated.'}`,
      });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await supabase.from('admins').update({
      password: hashedPassword,
      otp_code: null,
      otp_expiry: null,
      otp_attempts: 0
    }).eq('id', admin.id);

    res.json({ success: true, message: 'Admin password reset successfully. Please log in with your new password.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
