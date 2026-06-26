const https = require('https');

const sendVerificationEmail = async (to, code) => {
  console.log('[Email] sendVerificationEmail called for', to);

  const apiKey = process.env.BREVO_API_KEY;
  const senderEmail = process.env.BREVO_SENDER_EMAIL;
  if (!apiKey || !senderEmail) {
    console.warn('[Email] BREVO_API_KEY/BREVO_SENDER_EMAIL not set — skipping verification email.');
    return;
  }

  const payload = JSON.stringify({
    sender: { name: 'TaskGuard AI', email: senderEmail },
    to: [{ email: to }],
    subject: 'Your TaskGuard AI verification code',
    htmlContent: `
      <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <h2>Verify your email</h2>
        <p>Enter this code in the app to verify your account:</p>
        <p style="font-size: 32px; font-weight: 700; letter-spacing: 6px; color:#6C5CE7;">${code}</p>
        <p style="color:#888;font-size:12px;">This code expires in 10 minutes. If you didn't request this, you can ignore this email.</p>
      </div>
    `,
  });

  try {
    await new Promise((resolve, reject) => {
      const req = https.request(
        {
          hostname: 'api.brevo.com',
          path: '/v3/smtp/email',
          method: 'POST',
          headers: {
            'content-type': 'application/json',
            accept: 'application/json',
            'api-key': apiKey,
            'content-length': Buffer.byteLength(payload),
          },
          timeout: 10000,
        },
        (res) => {
          let body = '';
          res.on('data', (d) => (body += d));
          res.on('end', () => {
            if (res.statusCode >= 200 && res.statusCode < 300) {
              console.log('[Email] Verification code sent via Brevo:', body);
              resolve();
            } else {
              reject(new Error(`Brevo ${res.statusCode}: ${body}`));
            }
          });
        }
      );
      req.on('timeout', () => req.destroy(new Error('Brevo request timed out')));
      req.on('error', reject);
      req.write(payload);
      req.end();
    });
  } catch (err) {
    console.error('[Email] Failed to send verification email:', err.message);
  }
};

module.exports = { sendVerificationEmail };
