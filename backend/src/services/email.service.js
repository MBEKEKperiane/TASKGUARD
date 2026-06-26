const nodemailer = require('nodemailer');

console.log(
  '[Email] Module loaded. GMAIL_USER set:', !!process.env.GMAIL_USER,
  '| GMAIL_APP_PASSWORD set:', !!process.env.GMAIL_APP_PASSWORD
);

const transporter =
  process.env.GMAIL_USER && process.env.GMAIL_APP_PASSWORD
    ? nodemailer.createTransport({
        host: 'smtp.gmail.com',
        port: 465,
        secure: true,
        auth: {
          user: process.env.GMAIL_USER,
          pass: process.env.GMAIL_APP_PASSWORD,
        },
        // Render's network has no outbound IPv6 route, but smtp.gmail.com
        // resolves to an IPv6 address by default — forcing IPv4 avoids
        // ENETUNREACH on connect.
        family: 4,
        // Fail fast instead of hanging if the host's network can't reach
        // Gmail's SMTP servers (some PaaS providers restrict outbound SMTP).
        connectionTimeout: 10000,
        greetingTimeout: 10000,
        socketTimeout: 10000,
      })
    : null;

const sendVerificationEmail = async (to, code) => {
  console.log('[Email] sendVerificationEmail called for', to);
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
