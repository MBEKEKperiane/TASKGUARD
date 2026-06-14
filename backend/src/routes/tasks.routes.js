const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/tasks.controller');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = Router();
router.use(authenticate);

router.get('/', ctrl.listTasks);
router.get('/today', ctrl.getTodayTasks);
router.get('/overdue', ctrl.getOverdueTasks);

router.post('/nlp',
  body('text').trim().notEmpty().withMessage('Text is required.'),
  validate,
  ctrl.createFromNLP
);

router.post('/',
  body('title').trim().notEmpty().withMessage('Title is required.'),
  body('priority').optional().isIn(['LOW', 'MEDIUM', 'HIGH', 'URGENT']),
  body('dueDate').optional().isISO8601(),
  body('startTime').optional().isISO8601(),
  body('estimatedDuration').optional().isInt({ min: 1 }),
  validate,
  ctrl.createTask
);

router.get('/:id', param('id').isUUID(), validate, ctrl.getTask);

router.put('/:id',
  param('id').isUUID(),
  body('title').optional().trim().notEmpty(),
  body('priority').optional().isIn(['LOW', 'MEDIUM', 'HIGH', 'URGENT']),
  validate,
  ctrl.updateTask
);

router.patch('/:id/complete', param('id').isUUID(), validate, ctrl.completeTask);
router.delete('/:id', param('id').isUUID(), validate, ctrl.deleteTask);

router.post('/:id/subtasks',
  param('id').isUUID(),
  body('title').trim().notEmpty(),
  validate,
  ctrl.addSubtask
);

router.patch('/subtasks/:subtaskId/complete',
  param('subtaskId').isUUID(),
  validate,
  ctrl.completeSubtask
);

module.exports = router;
