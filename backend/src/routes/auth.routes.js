const { Router } = require('express');
const { body } = require('express-validator');
const ctrl = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = Router();

router.post('/register',
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters.'),
  body('name').optional().trim().notEmpty(),
  validate,
  ctrl.register
);

router.post('/login',
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
  validate,
  ctrl.login
);

router.post('/google',
  body('idToken').notEmpty(),
  validate,
  ctrl.googleLogin
);

router.post('/refresh',
  body('refreshToken').notEmpty(),
  validate,
  ctrl.refreshToken
);

router.post('/forgot-password',
  body('email').isEmail().normalizeEmail(),
  validate,
  ctrl.forgotPassword
);

router.post('/verify-reset-code',
  body('email').isEmail().normalizeEmail(),
  body('code').isLength({ min: 6, max: 6 }).withMessage('Code must be 6 digits.'),
  validate,
  ctrl.verifyResetCode
);

router.post('/reset-password',
  body('resetSessionToken').notEmpty(),
  body('newPassword').isLength({ min: 8 }).withMessage('Password must be at least 8 characters.'),
  validate,
  ctrl.resetPassword
);

router.post('/verify-email',
  authenticate,
  body('code').isLength({ min: 6, max: 6 }).withMessage('Code must be 6 digits.'),
  validate,
  ctrl.verifyEmail
);
router.post('/resend-verification', authenticate, ctrl.resendVerification);

router.get('/me', authenticate, ctrl.getMe);
router.patch('/me', authenticate, body('name').trim().notEmpty().withMessage('Name is required.'), validate, ctrl.updateMe);
router.post('/logout', authenticate, ctrl.logout);

module.exports = router;
