const { Resend } = require('resend');

const resend = process.env.RESEND_API_KEY ? new Resend(process.env.RESEND_API_KEY) : null;

const sendVerificationEmail = async (to, code) => {
  if (!resend) {
    console.warn('[Email] RESEND_API_KEY not set — skipping verification email.');
    return;
  }

  // process.env.EMAIL_FROM is trimmed and stripped of accidental wrapping
  // quotes — some dashboards store pasted values with literal quote chars,
  // which Resend's API rejects as an invalid sender without throwing.
  const from = (process.env.EMAIL_FROM || 'TaskGuard AI <onboarding@resend.dev>')
    .trim()
    .replace(/^"(.*)"$/, '$1')
    .replace(/^'(.*)'$/, '$1');

  try {
    const { data, error } = await resend.emails.send({
      from,
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
    if (error) {
      console.error('[Email] Resend rejected the send:', JSON.stringify(error));
    } else {
      console.log('[Email] Verification code sent, id:', data?.id);
    }
  } catch (err) {
    console.error('[Email] Failed to send verification email:', err.message);
  }
};

module.exports = { sendVerificationEmail };
