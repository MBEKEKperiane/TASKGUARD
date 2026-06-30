const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const prisma = require('../config/database');
const { sendVerificationEmail, sendPasswordResetEmail } = require('../services/email.service');

const VERIFICATION_CODE_TTL_MS = 10 * 60 * 1000; // 10 minutes

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

const generateTokens = (userId) => {
  const accessToken = jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
  });
  const refreshToken = jwt.sign({ userId }, process.env.JWT_REFRESH_SECRET, {
    expiresIn: '30d',
  });
  return { accessToken, refreshToken };
};

// Generates a fresh 6-digit code for the user, saves it, and emails it.
const issueVerificationCode = async (user) => {
  const code = crypto.randomInt(0, 1000000).toString().padStart(6, '0');
  const verificationTokenExpiry = new Date(Date.now() + VERIFICATION_CODE_TTL_MS);

  await prisma.user.update({
    where: { id: user.id },
    data: { verificationToken: code, verificationTokenExpiry },
  });

  // Fire-and-forget — an SMTP connection that's slow or blocked outbound
  // must never hold up the HTTP response. Failures are logged internally
  // by sendVerificationEmail.
  sendVerificationEmail(user.email, code);
};

// POST /api/auth/register
const register = async (req, res, next) => {
  try {
    const { email, password, name } = req.body;
    const passwordHash = await bcrypt.hash(password, 12);

    const existing = await prisma.user.findUnique({ where: { email } });
    let user;
    if (existing) {
      // A verified account already owns this email — genuinely taken.
      if (existing.emailVerified) {
        return res.status(409).json({ error: 'Email already registered.' });
      }
      // Previous registration was never verified — let this attempt
      // claim it fresh instead of permanently locking the email.
      user = await prisma.user.update({
        where: { id: existing.id },
        data: { name, passwordHash },
      });
    } else {
      user = await prisma.user.create({
        data: { email, name, passwordHash },
      });
    }

    const { accessToken, refreshToken } = generateTokens(user.id);
    await prisma.user.update({
      where: { id: user.id },
      data: { refreshToken },
    });

    await issueVerificationCode(user);

    res.status(201).json({
      user: { id: user.id, email: user.email, name: user.name, emailVerified: user.emailVerified },
      accessToken,
      refreshToken,
    });
  } catch (err) {
    next(err);
  }
};

// POST /api/auth/login
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.passwordHash) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const { accessToken, refreshToken } = generateTokens(user.id);
    await prisma.user.update({
      where: { id: user.id },
      data: { refreshToken },
    });

    // Every email/password login requires a fresh 6-digit code as a
    // second factor — issued unconditionally, regardless of whether this
    // email was already verified in the past.
    await issueVerificationCode(user);

    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        theme: user.theme,
        emailVerified: false,
      },
      accessToken,
      refreshToken,
    });
  } catch (err) {
    next(err);
  }
};

// POST /api/auth/google
const googleLogin = async (req, res, next) => {
  try {
    const { idToken } = req.body;

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { sub: googleId, email, name } = payload;

    let user = await prisma.user.findFirst({
      where: { OR: [{ googleId }, { email }] },
    });

    if (!user) {
      user = await prisma.user.create({
        data: { email, name, googleId, emailVerified: true },
      });
    } else if (!user.googleId) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { googleId, emailVerified: true },
      });
    }

    const { accessToken, refreshToken } = generateTokens(user.id);
    await prisma.user.update({
      where: { id: user.id },
      data: { refreshToken },
    });

    res.json({
      user: { id: user.id, email: user.email, name: user.name, emailVerified: user.emailVerified },
      accessToken,
      refreshToken,
    });
  } catch (err) {
    next(err);
  }
};

// POST /api/auth/refresh
const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken: token } = req.body;
    if (!token) return res.status(401).json({ error: 'Refresh token required.' });

    const decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
    const user = await prisma.user.findUnique({ where: { id: decoded.userId } });

    if (!user || user.refreshToken !== token) {
      return res.status(401).json({ error: 'Invalid refresh token.' });
    }

    const { accessToken, refreshToken: newRefresh } = generateTokens(user.id);
    await prisma.user.update({
      where: { id: user.id },
      data: { refreshToken: newRefresh },
    });

    res.json({ accessToken, refreshToken: newRefresh });
  } catch (err) {
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Invalid or expired refresh token.' });
    }
    next(err);
  }
};

// POST /api/auth/verify-email  { code }
const verifyEmail = async (req, res, next) => {
  try {
    const { code } = req.body;
    const user = await prisma.user.findUnique({ where: { id: req.user.id } });

    if (!user) return res.status(404).json({ error: 'User not found.' });

    // No early-exit for already-verified accounts — every login now
    // requires its own fresh code to be checked as a second factor.
    const isValid =
      code &&
      user.verificationToken === code &&
      user.verificationTokenExpiry &&
      user.verificationTokenExpiry > new Date();

    if (!isValid) {
      return res.status(400).json({ error: 'Invalid or expired code.' });
    }

    await prisma.user.update({
      where: { id: user.id },
      data: { emailVerified: true, verificationToken: null, verificationTokenExpiry: null },
    });

    res.json({ message: 'Email verified successfully.' });
  } catch (err) {
    next(err);
  }
};

// POST /api/auth/resend-verification
const resendVerification = async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    if (!user) return res.status(404).json({ error: 'User not found.' });

    await issueVerificationCode(user);

    res.json({ message: 'Verification code sent.' });
  } catch (err) {
    next(err);
  }
};

// POST /api/auth/forgot-password  { email }
// Only works for accounts that registered with a password — Google-only
// accounts have nothing to "forget" and sign in via Google instead.
const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    const user = await prisma.user.findUnique({ where: { email } });

    if (!user) {
      return res.status(404).json({ error: 'No account is registered with that email.' });
    }
    if (!user.passwordHash) {
      return res.status(400).json({
        error: 'This account signs in with Google. Use "Continue with Google" instead.',
      });
    }

    const code = crypto.randomInt(0, 1000000).toString().padStart(6, '0');
    const resetTokenExpiry = new Date(Date.now() + VERIFICATION_CODE_TTL_MS);

    await prisma.user.update({
      where: { id: user.id },
      data: { resetToken: code, resetTokenExpiry },
    });

    // Fire-and-forget, same reasoning as issueVerificationCode.
    sendPasswordResetEmail(user.email, code);

    res.json({ message: 'A 6-digit code has been sent to your email.' });
  } catch (err) {
    next(err);
  }
};

// POST /api/auth/verify-reset-code  { email, code }
// Validates the code, consumes it, and issues a short-lived session token
// that authorizes the password-reset step that follows.
const verifyResetCode = async (req, res, next) => {
  try {
    const { email, code } = req.body;
    const user = await prisma.user.findUnique({ where: { email } });

    const isValid =
      user &&
      code &&
      user.resetToken === code &&
      user.resetTokenExpiry &&
      user.resetTokenExpiry > new Date();

    if (!isValid) {
      return res.status(400).json({ error: 'Invalid or expired code.' });
    }

    await prisma.user.update({
      where: { id: user.id },
      data: { resetToken: null, resetTokenExpiry: null },
    });

    const resetSessionToken = jwt.sign(
      { userId: user.id, purpose: 'password_reset' },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );

    res.json({ resetSessionToken });
  } catch (err) {
    next(err);
  }
};

// POST /api/auth/reset-password  { resetSessionToken, newPassword }
// Completes the flow: sets the new password and logs the user straight
// into the dashboard, since the code step already proved email ownership.
const resetPassword = async (req, res, next) => {
  try {
    const { resetSessionToken, newPassword } = req.body;

    let decoded;
    try {
      decoded = jwt.verify(resetSessionToken, process.env.JWT_SECRET);
    } catch {
      decoded = null;
    }
    if (!decoded || decoded.purpose !== 'password_reset') {
      return res.status(400).json({ error: 'Invalid or expired reset session. Please start over.' });
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);
    const { accessToken, refreshToken } = generateTokens(decoded.userId);

    const user = await prisma.user.update({
      where: { id: decoded.userId },
      data: { passwordHash, refreshToken, emailVerified: true },
    });

    res.json({
      message: 'Password reset successfully.',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        theme: user.theme,
        emailVerified: user.emailVerified,
      },
      accessToken,
      refreshToken,
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/auth/me
const getMe = async (req, res) => {
  res.json({ user: req.user });
};

// PATCH /api/auth/me
const updateMe = async (req, res, next) => {
  try {
    const { name } = req.body;
    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: { name },
    });
    res.json({ user: { id: user.id, email: user.email, name: user.name } });
  } catch (err) {
    next(err);
  }
};

// POST /api/auth/logout
const logout = async (req, res, next) => {
  try {
    await prisma.user.update({
      where: { id: req.user.id },
      data: { refreshToken: null },
    });
    res.json({ message: 'Logged out successfully.' });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  register, login, googleLogin, refreshToken,
  verifyEmail, resendVerification,
  forgotPassword, verifyResetCode, resetPassword, getMe, updateMe, logout,
};
