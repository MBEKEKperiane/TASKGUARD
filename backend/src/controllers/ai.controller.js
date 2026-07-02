const prisma = require('../config/database');
const aiService = require('../services/ai.service');

// POST /api/ai/chat
const chat = async (req, res, next) => {
  try {
    const { message } = req.body;
    const userId = req.user.id;

    // Fetch recent history
    const history = await prisma.chatMessage.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
      take: 20,
      select: { role: true, content: true },
    });

    let reply;
    try {
      reply = await aiService.chat(userId, message, history);
    } catch (aiErr) {
      console.error('[AI Chat] OpenRouter error:', aiErr.message);
      return res.status(503).json({
        error: 'AI service temporarily unavailable.',
        code: 'AI_OFFLINE',
      });
    }

    // Persist both messages
    await prisma.chatMessage.createMany({
      data: [
        { userId, role: 'user', content: message },
        { userId, role: 'assistant', content: reply },
      ],
    });

    res.json({ reply, timestamp: new Date() });
  } catch (err) {
    next(err);
  }
};

// GET /api/ai/chat/history
const getChatHistory = async (req, res, next) => {
  try {
    const messages = await prisma.chatMessage.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'asc' },
      take: 50,
    });
    res.json({ messages });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/ai/chat/history
const clearChatHistory = async (req, res, next) => {
  try {
    await prisma.chatMessage.deleteMany({ where: { userId: req.user.id } });
    res.json({ message: 'Chat history cleared.' });
  } catch (err) {
    next(err);
  }
};

// GET /api/ai/daily-plan
const getDailyPlan = async (req, res, next) => {
  try {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const end = new Date();
    end.setHours(23, 59, 59, 999);

    const tasks = await prisma.task.findMany({
      where: {
        userId: req.user.id,
        isCompleted: false,
        OR: [
          { dueDate: { gte: start, lte: end } },
          { startTime: { gte: start, lte: end } },
        ],
      },
    });

    const plan = await aiService.generateDailyPlan(tasks);
    res.json(plan);
  } catch (err) {
    next(err);
  }
};

// POST /api/ai/prioritize
const prioritizeTasks = async (req, res, next) => {
  try {
    const tasks = await prisma.task.findMany({
      where: { userId: req.user.id, isCompleted: false },
    });

    if (!tasks.length) return res.json({ message: 'No tasks to prioritize.', tasks: [] });

    const scored = await aiService.reprioritizeTasks(tasks);

    // Persist scores
    await Promise.all(
      scored.map((s) =>
        prisma.task.update({
          where: { id: s.id },
          data: { aiPriorityScore: s.aiPriorityScore },
        }).catch(() => null)
      )
    );

    res.json({ scored, message: `${scored.length} tasks re-prioritized.` });
  } catch (err) {
    next(err);
  }
};

// GET /api/ai/overload-check
const overloadCheck = async (req, res, next) => {
  try {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const end = new Date();
    end.setHours(23, 59, 59, 999);

    const [tasks, focusSessions] = await Promise.all([
      prisma.task.findMany({
        where: {
          userId: req.user.id,
          isCompleted: false,
          OR: [
            { dueDate: { gte: start, lte: end } },
            { status: 'OVERDUE' },
          ],
        },
      }),
      prisma.focusSession.findMany({
        where: {
          userId: req.user.id,
          startedAt: { gte: start },
          completed: true,
        },
        select: { actualMins: true, plannedMins: true },
      }),
    ]);

    const focusMinutesToday = focusSessions.reduce(
      (s, f) => s + (f.actualMins || f.plannedMins || 0), 0
    );

    const result = await aiService.checkOverload(tasks, focusMinutesToday);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

// GET /api/ai/suggest-time/:taskId
const suggestTime = async (req, res, next) => {
  try {
    const task = await prisma.task.findFirst({
      where: { id: req.params.taskId, userId: req.user.id },
    });
    if (!task) return res.status(404).json({ error: 'Task not found.' });

    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const end = new Date();
    end.setHours(23, 59, 59, 999);

    const existingTasks = await prisma.task.findMany({
      where: {
        userId: req.user.id,
        startTime: { gte: start, lte: end },
        id: { not: task.id },
      },
      select: { title: true, startTime: true, estimatedDuration: true },
    });

    const suggestion = await aiService.suggestBestTime(task, existingTasks);
    res.json(suggestion);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  chat, getChatHistory, clearChatHistory,
  getDailyPlan, prioritizeTasks, overloadCheck, suggestTime,
};
