const prisma = require('../config/database');
const { scorePriority } = require('../services/ai.service');

const taskSelect = {
  id: true, title: true, description: true, dueDate: true,
  startTime: true, estimatedDuration: true, category: true,
  priority: true, aiPriorityScore: true, status: true,
  recurrenceType: true, isCompleted: true, completedAt: true,
  createdAt: true, updatedAt: true,
  subtasks: { select: { id: true, title: true, isCompleted: true } },
  reminders: { select: { id: true, remindAt: true, sent: true } },
};

// GET /api/tasks
const listTasks = async (req, res, next) => {
  try {
    const { status, priority, category, from, to, search } = req.query;
    const where = { userId: req.user.id };

    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (category) where.category = category;
    if (search) where.title = { contains: search, mode: 'insensitive' };
    if (from || to) {
      where.dueDate = {};
      if (from) where.dueDate.gte = new Date(from);
      if (to) where.dueDate.lte = new Date(to);
    }

    const tasks = await prisma.task.findMany({
      where,
      select: taskSelect,
      orderBy: [{ aiPriorityScore: 'desc' }, { dueDate: 'asc' }],
    });

    res.json({ tasks });
  } catch (err) {
    next(err);
  }
};

// GET /api/tasks/today — returns incomplete tasks: due within 7 days OR undated
const getTodayTasks = async (req, res, next) => {
  try {
    const now = new Date();
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() + 7);
    cutoff.setHours(23, 59, 59, 999);

    const tasks = await prisma.task.findMany({
      where: {
        userId: req.user.id,
        isCompleted: false,
        OR: [
          { dueDate: { gte: now, lte: cutoff } },
          { startTime: { gte: now, lte: cutoff } },
          { dueDate: null, startTime: null },
        ],
      },
      select: taskSelect,
      orderBy: [{ dueDate: 'asc' }, { startTime: 'asc' }, { aiPriorityScore: 'desc' }],
    });

    res.json({ tasks });
  } catch (err) {
    next(err);
  }
};

// GET /api/tasks/overdue
const getOverdueTasks = async (req, res, next) => {
  try {
    const now = new Date();
    const tasks = await prisma.task.findMany({
      where: {
        userId: req.user.id,
        dueDate: { lt: now },
        isCompleted: false,
      },
      select: taskSelect,
      orderBy: { dueDate: 'asc' },
    });

    // Mark them as overdue in DB
    if (tasks.length > 0) {
      await prisma.task.updateMany({
        where: {
          userId: req.user.id,
          dueDate: { lt: now },
          isCompleted: false,
          status: { not: 'OVERDUE' },
        },
        data: { status: 'OVERDUE' },
      });
    }

    res.json({ tasks });
  } catch (err) {
    next(err);
  }
};

// GET /api/tasks/:id
const getTask = async (req, res, next) => {
  try {
    const task = await prisma.task.findFirst({
      where: { id: req.params.id, userId: req.user.id },
      select: taskSelect,
    });
    if (!task) return res.status(404).json({ error: 'Task not found.' });
    res.json({ task });
  } catch (err) {
    next(err);
  }
};

// POST /api/tasks
const createTask = async (req, res, next) => {
  try {
    const {
      title, description, dueDate, startTime, estimatedDuration,
      category, priority, recurrenceType, subtasks, remindAt,
    } = req.body;

    // Save task immediately — no AI wait
    const task = await prisma.task.create({
      data: {
        userId: req.user.id,
        title,
        description,
        dueDate: dueDate ? new Date(dueDate) : null,
        startTime: startTime ? new Date(startTime) : null,
        estimatedDuration: estimatedDuration ? Number(estimatedDuration) : null,
        category,
        priority: priority || 'MEDIUM',
        aiPriorityScore: null,
        recurrenceType: recurrenceType || 'NONE',
        subtasks: subtasks?.length
          ? { create: subtasks.map((t) => ({ title: t })) }
          : undefined,
        reminders: remindAt
          ? { create: [{ remindAt: new Date(remindAt) }] }
          : undefined,
      },
      select: taskSelect,
    });

    // Respond immediately — don't make the user wait
    res.status(201).json({ task });

    // AI scoring + productivity update run in the background after response
    scorePriority({ title, description, dueDate, priority, estimatedDuration })
      .then(score => {
        if (score != null) {
          prisma.task.update({ where: { id: task.id }, data: { aiPriorityScore: score } }).catch(() => {});
        }
      })
      .catch(() => {});
    upsertProductivityData(req.user.id).catch(() => {});
  } catch (err) {
    next(err);
  }
};

// PUT /api/tasks/:id
const updateTask = async (req, res, next) => {
  try {
    const existing = await prisma.task.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Task not found.' });

    const {
      title, description, dueDate, startTime, estimatedDuration,
      category, priority, recurrenceType, status,
    } = req.body;

    const task = await prisma.task.update({
      where: { id: req.params.id },
      data: {
        title, description,
        dueDate: dueDate ? new Date(dueDate) : undefined,
        startTime: startTime ? new Date(startTime) : undefined,
        estimatedDuration: estimatedDuration ? Number(estimatedDuration) : undefined,
        category, priority, recurrenceType, status,
      },
      select: taskSelect,
    });

    res.json({ task });
  } catch (err) {
    next(err);
  }
};

// PATCH /api/tasks/:id/complete
const completeTask = async (req, res, next) => {
  try {
    const existing = await prisma.task.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Task not found.' });

    const task = await prisma.task.update({
      where: { id: req.params.id },
      data: {
        isCompleted: true,
        status: 'COMPLETED',
        completedAt: new Date(),
      },
      select: taskSelect,
    });

    await upsertProductivityData(req.user.id, true);

    res.json({ task });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/tasks/:id
const deleteTask = async (req, res, next) => {
  try {
    const existing = await prisma.task.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Task not found.' });

    await prisma.task.delete({ where: { id: req.params.id } });
    res.json({ message: 'Task deleted.' });
  } catch (err) {
    next(err);
  }
};

// POST /api/tasks/:id/subtasks
const addSubtask = async (req, res, next) => {
  try {
    const task = await prisma.task.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!task) return res.status(404).json({ error: 'Task not found.' });

    const subtask = await prisma.subtask.create({
      data: { taskId: req.params.id, title: req.body.title },
    });
    res.status(201).json({ subtask });
  } catch (err) {
    next(err);
  }
};

// PATCH /api/tasks/subtasks/:subtaskId/complete
const completeSubtask = async (req, res, next) => {
  try {
    const subtask = await prisma.subtask.update({
      where: { id: req.params.subtaskId },
      data: { isCompleted: req.body.isCompleted ?? true },
    });
    res.json({ subtask });
  } catch (err) {
    next(err);
  }
};

// POST /api/tasks/nlp  – create task from natural language
const createFromNLP = async (req, res, next) => {
  try {
    const { parseNaturalLanguageTask } = require('../services/ai.service');
    const parsed = await parseNaturalLanguageTask(req.body.text);

    const task = await prisma.task.create({
      data: {
        userId: req.user.id,
        title: parsed.title,
        description: parsed.description,
        dueDate: parsed.dueDate ? new Date(parsed.dueDate) : null,
        startTime: parsed.startTime ? new Date(parsed.startTime) : null,
        estimatedDuration: parsed.estimatedDuration || null,
        priority: parsed.priority || 'MEDIUM',
        reminders: parsed.remindAt
          ? { create: [{ remindAt: new Date(parsed.remindAt) }] }
          : undefined,
      },
      select: taskSelect,
    });

    res.status(201).json({ task, parsed });
  } catch (err) {
    next(err);
  }
};

async function upsertProductivityData(userId, completed = false) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  await prisma.productivityData.upsert({
    where: { userId_date: { userId, date: today } },
    create: {
      userId, date: today,
      tasksPlanned: 1,
      tasksCompleted: completed ? 1 : 0,
    },
    update: {
      tasksPlanned: { increment: completed ? 0 : 1 },
      tasksCompleted: { increment: completed ? 1 : 0 },
    },
  });
}

module.exports = {
  listTasks, getTodayTasks, getOverdueTasks, getTask,
  createTask, updateTask, completeTask, deleteTask,
  addSubtask, completeSubtask, createFromNLP,
};
