const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/focus.controller');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = Router();
router.use(authenticate);

router.post('/start',
  body('plannedMins').optional().isInt({ min: 1, max: 120 }),
  body('taskTitle').optional().trim(),
  validate,
  ctrl.startSession
);

router.patch('/:id/end',
  param('id').isUUID(),
  validate,
  ctrl.endSession
);

router.get('/sessions', ctrl.getSessions);
router.get('/stats', ctrl.getStats);

module.exports = router;
