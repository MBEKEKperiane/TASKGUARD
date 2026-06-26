const nodemailer = require('nodemailer');

const transporter =
  process.env.GMAIL_USER && process.env.GMAIL_APP_PASSWORD
    ? nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: process.env.GMAIL_USER,
          pass: process.env.GMAIL_APP_PASSWORD,
        },
      })
    : null;

const sendVerificationEmail = async (to, code) => {
  if (!transporter) {
    console.warn('[Email] GMAIL_USER/GMAIL_APP_PASSWORD not set — skipping verification email.');
    return;
  }

  try {
    const info = await transporter.sendMail({
      from: `TaskGuard AI <${process.env.GMAIL_USER}>`,
      to,
      subject: 'Your TaskGuard AI verification code',
      html: `
        <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
          <h2>Verify your email</h2>
          <p>Enter this code in the app to verify your account:</p>
          <p style="font-size: 32px; font-weight: 700; letter-spacing: 6px; color:#6C5CE7;">${code}</p>
          <p style="color:#888;font-size:12px;">This code expires in 10 minutes. If you didn't request this, you can ignore this email.</p>
        </div>
      `,
    });
    console.log('[Email] Verification code sent, id:', info.messageId);
  } catch (err) {
    console.error('[Email] Failed to send verification email:', err.message);
  }
};

module.exports = { sendVerificationEmail };
