const { Router } = require('express');
const ctrl = require('../controllers/insights.controller');
const { authenticate } = require('../middleware/auth');

const router = Router();
router.use(authenticate);

router.get('/weekly', ctrl.getWeeklyInsights);
router.get('/score', ctrl.getProductivityScore);
router.get('/peak-hours', ctrl.getPeakHours);
router.get('/milestones', ctrl.getMilestones);

module.exports = router;
