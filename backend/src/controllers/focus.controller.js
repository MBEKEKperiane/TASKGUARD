const prisma = require('../config/database');

// POST /api/focus/start
const startSession = async (req, res, next) => {
  try {
    const { plannedMins = 25, taskTitle } = req.body;

    const session = await prisma.focusSession.create({
      data: {
        userId: req.user.id,
        plannedMins: Number(plannedMins),
        taskTitle,
      },
    });

    res.status(201).json({ session });
  } catch (err) {
    next(err);
  }
};

// PATCH /api/focus/:id/end
const endSession = async (req, res, next) => {
  try {
    const session = await prisma.focusSession.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!session) return res.status(404).json({ error: 'Session not found.' });

    const endedAt = new Date();
    const actualMins = Math.round((endedAt - session.startedAt) / 60000);
    const completed = actualMins >= session.plannedMins * 0.8;

    const updated = await prisma.focusSession.update({
      where: { id: req.params.id },
      data: { endedAt, actualMins, completed },
    });

    // Update today's productivity data with focus minutes
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    await prisma.productivityData.upsert({
      where: { userId_date: { userId: req.user.id, date: today } },
      create: { userId: req.user.id, date: today, focusMinutes: actualMins },
      update: { focusMinutes: { increment: actualMins } },
    });

    res.json({ session: updated, actualMins, completed });
  } catch (err) {
    next(err);
  }
};

// GET /api/focus/sessions
const getSessions = async (req, res, next) => {
  try {
    const { limit = 20, offset = 0 } = req.query;
    const sessions = await prisma.focusSession.findMany({
      where: { userId: req.user.id },
      orderBy: { startedAt: 'desc' },
      take: Number(limit),
      skip: Number(offset),
    });
    res.json({ sessions });
  } catch (err) {
    next(err);
  }
};

// GET /api/focus/stats
const getStats = async (req, res, next) => {
  try {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const sessions = await prisma.focusSession.findMany({
      where: { userId: req.user.id, startedAt: { gte: sevenDaysAgo } },
    });

    const totalSessions = sessions.length;
    const completedSessions = sessions.filter((s) => s.completed).length;
    const totalMinutes = sessions.reduce((s, f) => s + (f.actualMins || 0), 0);
    const avgMinutesPerSession = totalSessions
      ? Math.round(totalMinutes / totalSessions)
      : 0;
    const completionRate = totalSessions
      ? Math.round((completedSessions / totalSessions) * 100)
      : 0;

    // Build daily breakdown
    const dailyMap = {};
    sessions.forEach((s) => {
      const day = s.startedAt.toISOString().split('T')[0];
      dailyMap[day] = (dailyMap[day] || 0) + (s.actualMins || 0);
    });

    res.json({
      totalSessions,
      completedSessions,
      completionRate,
      totalMinutes,
      avgMinutesPerSession,
      dailyBreakdown: dailyMap,
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { startSession, endSession, getSessions, getStats };
