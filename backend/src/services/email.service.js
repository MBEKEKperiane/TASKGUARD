const nodemailer = require('nodemailer');
const dns = require('dns').promises;

console.log(
  '[Email] Module loaded. GMAIL_USER set:', !!process.env.GMAIL_USER,
  '| GMAIL_APP_PASSWORD set:', !!process.env.GMAIL_APP_PASSWORD
);

const hasCreds = !!(process.env.GMAIL_USER && process.env.GMAIL_APP_PASSWORD);

let cachedTransporter = null;

// Render's network has no outbound IPv6 route, but smtp.gmail.com resolves
// to an IPv6 address by default and nodemailer's `family` option doesn't
// reliably override that. Resolving the A record ourselves and connecting
// to the literal IPv4 address sidesteps it; `tls.servername` keeps TLS
// certificate validation working against the real hostname.
const getTransporter = async () => {
  if (cachedTransporter) return cachedTransporter;

  const addresses = await dns.resolve4('smtp.gmail.com');
  const ipv4Host = addresses[0];
  console.log('[Email] Resolved smtp.gmail.com ->', ipv4Host);

  cachedTransporter = nodemailer.createTransport({
    host: ipv4Host,
    port: 587,
    secure: false,
    requireTLS: true,
    tls: { servername: 'smtp.gmail.com' },
    auth: {
      user: process.env.GMAIL_USER,
      pass: process.env.GMAIL_APP_PASSWORD,
    },
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 10000,
  });
  return cachedTransporter;
};

const sendVerificationEmail = async (to, code) => {
  console.log('[Email] sendVerificationEmail called for', to);
  if (!hasCreds) {
    console.warn('[Email] GMAIL_USER/GMAIL_APP_PASSWORD not set — skipping verification email.');
    return;
  }

  try {
    const transporter = await getTransporter();
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
