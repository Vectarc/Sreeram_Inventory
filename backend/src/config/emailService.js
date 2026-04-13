const nodemailer = require('nodemailer');

// ─────────────────────────────────────────────────────────────────
// EMAIL TRANSPORTER SETUP
// Configure via .env variables:
//   EMAIL_HOST     → SMTP host  (e.g. smtp.gmail.com)
//   EMAIL_PORT     → SMTP port  (e.g. 587)
//   EMAIL_USER     → your email address
//   EMAIL_PASS     → your email password or App Password
//   EMAIL_FROM     → display name + address (e.g. "Sree Ram Co <you@gmail.com>")
//
// For Gmail: enable 2-Step Verification, then create an App Password at
//   https://myaccount.google.com/apppasswords
//   Use that 16-char App Password as EMAIL_PASS
// ─────────────────────────────────────────────────────────────────
// Trim / normalize common env var mistakes (e.g. copied app passwords with spaces)
const emailUser = process.env.EMAIL_USER ? process.env.EMAIL_USER.trim() : '';
const emailPass = process.env.EMAIL_PASS ? process.env.EMAIL_PASS.replace(/\s+/g, '').trim() : '';

const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.EMAIL_PORT || '587'),
    secure: process.env.EMAIL_PORT === '465', // true only for port 465
    auth: {
      user: emailUser,
      pass: emailPass,
    },
    tls: {
      rejectUnauthorized: false, // allows self-signed certs on local setups
    },
  });
};

// ─────────────────────────────────────────────────────────────────
// SEND OTP EMAIL
// ─────────────────────────────────────────────────────────────────
const sendOtpEmail = async ({ toEmail, toName, otp, expiryMinutes = 2 }) => {
  // If email credentials are not configured, log to console (dev mode)
  if (!emailUser || !emailPass) {
    console.log('⚠️  EMAIL NOT CONFIGURED — OTP (dev mode):', otp);
    console.log('   Set EMAIL_USER and EMAIL_PASS in your .env file to send real emails.');
    return { success: true, devMode: true, otp };
  }

  const transporter = createTransporter();

  const mailOptions = {
    from: process.env.EMAIL_FROM || `"Sree Ram Company" <${process.env.EMAIL_USER}>`,
    to: `${toName ? toName + ' <' + toEmail + '>' : toEmail}`,
    subject: '🔐 Admin Password Reset OTP — Sree Ram Company',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: 'Segoe UI', Arial, sans-serif; background: #f4f4f7; margin: 0; padding: 0; }
          .container { max-width: 480px; margin: 32px auto; background: #fff; border-radius: 14px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.10); }
          .header { background: linear-gradient(135deg, #e53935, #ff9800); padding: 28px 24px; text-align: center; }
          .header h1 { color: #fff; margin: 0; font-size: 20px; font-weight: 800; letter-spacing: 0.5px; }
          .header p { color: rgba(255,255,255,0.85); margin: 6px 0 0; font-size: 13px; }
          .body { padding: 28px 28px 20px; }
          .greeting { font-size: 15px; color: #333; margin-bottom: 16px; }
          .otp-box { background: #fff3e0; border: 2px dashed #ff9800; border-radius: 12px; text-align: center; padding: 20px 12px; margin: 20px 0; }
          .otp-label { font-size: 12px; color: #999; text-transform: uppercase; letter-spacing: 1.5px; margin-bottom: 8px; }
          .otp-code { font-size: 40px; font-weight: 900; color: #e53935; letter-spacing: 10px; margin: 0; }
          .timer-box { background: #e8f5e9; border-radius: 8px; padding: 10px 16px; margin: 0 0 20px; text-align: center; }
          .timer-text { color: #388e3c; font-size: 13px; font-weight: 600; margin: 0; }
          .warning { background: #fff8e1; border-left: 4px solid #ffc107; border-radius: 4px; padding: 10px 14px; font-size: 12px; color: #795548; margin-bottom: 20px; }
          .footer { background: #f9f9f9; border-top: 1px solid #eee; padding: 16px 28px; text-align: center; }
          .footer p { font-size: 11px; color: #aaa; margin: 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🔐 Password Reset OTP</h1>
            <p>Sree Ram Dyes &amp; Chemicals</p>
          </div>
          <div class="body">
            <p class="greeting">Hello <strong>${toName || 'Admin'}</strong>,</p>
            <p style="font-size:14px;color:#555;">We received a request to reset the admin password. Use the OTP below to proceed:</p>
            <div class="otp-box">
              <p class="otp-label">Your One-Time Password</p>
              <p class="otp-code">${otp}</p>
            </div>
            <div class="timer-box">
              <p class="timer-text">⏱ This OTP is valid for <strong>${expiryMinutes} minutes</strong> only</p>
            </div>
            <div class="warning">
              <strong>⚠️ Security Notice:</strong> Never share this OTP with anyone. If you did not request a password reset, please ignore this email or contact the system administrator immediately.
            </div>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} Sree Ram Dyes &amp; Chemicals · This is an automated message, please do not reply.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `Your OTP for admin password reset is: ${otp}\nThis OTP is valid for ${expiryMinutes} minutes.\nDo not share this with anyone.`,
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (err) {
    console.error('❌ Email send error:', err.message);
    return { success: false, message: err.message };
  }
};

module.exports = { sendOtpEmail };
