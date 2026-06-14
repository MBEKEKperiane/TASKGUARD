const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/notifications.controller');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = Router();
router.use(authenticate);

router.post('/token',
  body('token').trim().notEmpty(),
  validate,
  ctrl.saveFcmToken
);

router.get('/', ctrl.listNotifications);
router.patch('/read-all', ctrl.markAllRead);
router.patch('/:id/read', param('id').isUUID(), validate, ctrl.markRead);

module.exports = router;
