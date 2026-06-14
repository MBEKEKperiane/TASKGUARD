const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/ai.controller');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = Router();
router.use(authenticate);

router.post('/chat',
  body('message').trim().notEmpty().withMessage('Message is required.'),
  validate,
  ctrl.chat
);

router.get('/chat/history', ctrl.getChatHistory);
router.delete('/chat/history', ctrl.clearChatHistory);
router.get('/daily-plan', ctrl.getDailyPlan);
router.post('/prioritize', ctrl.prioritizeTasks);
router.get('/overload-check', ctrl.overloadCheck);

router.get('/suggest-time/:taskId',
  param('taskId').isUUID(),
  validate,
  ctrl.suggestTime
);

module.exports = router;
