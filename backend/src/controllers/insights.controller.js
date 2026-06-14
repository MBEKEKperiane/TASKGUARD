const prisma = require('../config/database');
const { generateInsights } = require('../services/ai.service');

// GET /api/insights/weekly
const getWeeklyInsights = async (req, res, next) => {
  try {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    const [productivityRows, focusSessions, completedTasks] = await Promise.all([
      prisma.productivityData.findMany({
        where: { userId: req.user.id, date: { gte: sevenDaysAgo } },
        orderBy: { date: 'asc' },
      }),
      prisma.focusSession.findMany({
        where: { userId: req.user.id, startedAt: { gte: sevenDaysAgo } },
      }),
      prisma.task.findMany({
        where: {
          userId: req.user.id,
          completedAt: { gte: sevenDaysAgo },
          isCompleted: true,
        },
      }),
    ]);

    const totalTasksCompleted = completedTasks.length;
    const totalFocusMinutes = focusSessions.reduce(
      (s, f) => s + (f.actualMins || 0), 0
    );
    const avgProductivityScore = productivityRows.length
      ? productivityRows.reduce((s, r) => s + (r.productivityScore || 0), 0) /
        productivityRows.length
      : 0;

    // Build daily chart data
    const dailyData = productivityRows.map((r) => ({
      date: r.date,
      tasksCompleted: r.tasksCompleted,
      focusMinutes: r.focusMinutes,
      productivityScore: r.productivityScore,
    }));

    // AI-generated insights
    const aiInsights = await generateInsights({
      totalTasksCompleted,
      totalFocusMinutes,
      avgProductivityScore: Math.round(avgProductivityScore),
      dailyData,
    }).catch(() => null);

    res.json({
      weekly: {
        totalTasksCompleted,
        totalFocusMinutes,
        avgProductivityScore: Math.round(avgProductivityScore),
        dailyData,
      },
      aiInsights,
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/insights/score
const getProductivityScore = async (req, res, next) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [data, totalTasks, completedTasks, overdueTasks, focusSessions] =
      await Promise.all([
        prisma.productivityData.findUnique({
          where: { userId_date: { userId: req.user.id, date: today } },
        }),
        prisma.task.count({
          where: { userId: req.user.id, dueDate: { gte: today } },
        }),
        prisma.task.count({
          where: { userId: req.user.id, isCompleted: true, completedAt: { gte: today } },
        }),
        prisma.task.count({
          where: { userId: req.user.id, status: 'OVERDUE' },
        }),
        prisma.focusSession.findMany({
          where: { userId: req.user.id, startedAt: { gte: today }, completed: true },
          select: { actualMins: true },
        }),
      ]);

    const focusMinutesToday = focusSessions.reduce(
      (s, f) => s + (f.actualMins || 0), 0
    );

    // Score algorithm: completion rate + focus time + no overdue penalty
    const completionRate = totalTasks > 0
      ? (completedTasks / totalTasks) * 50
      : 50;
    const focusBonus = Math.min(30, focusMinutesToday / 8);
    const overduePenalty = Math.min(30, overdueTasks * 5);
    const score = Math.max(0, Math.round(completionRate + focusBonus - overduePenalty));

    // Persist
    await prisma.productivityData.upsert({
      where: { userId_date: { userId: req.user.id, date: today } },
      create: { userId: req.user.id, date: today, productivityScore: score },
      update: { productivityScore: score },
    });

    res.json({
      score,
      label: score >= 80 ? 'Elite' : score >= 60 ? 'Good' : score >= 40 ? 'Fair' : 'Needs Work',
      breakdown: { completionRate: Math.round(completionRate), focusBonus: Math.round(focusBonus), overduePenalty },
      stats: { totalTasks, completedTasks, overdueTasks, focusMinutesToday },
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/insights/peak-hours
const getPeakHours = async (req, res, next) => {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const completedTasks = await prisma.task.findMany({
      where: {
        userId: req.user.id,
        completedAt: { gte: thirtyDaysAgo },
        isCompleted: true,
      },
      select: { completedAt: true },
    });

    const focusSessions = await prisma.focusSession.findMany({
      where: {
        userId: req.user.id,
        startedAt: { gte: thirtyDaysAgo },
        completed: true,
      },
      select: { startedAt: true, actualMins: true },
    });

    // Count completions per hour
    const hourActivity = Array(24).fill(0);
    completedTasks.forEach((t) => {
      hourActivity[t.completedAt.getHours()]++;
    });
    focusSessions.forEach((s) => {
      hourActivity[s.startedAt.getHours()] += Math.round((s.actualMins || 0) / 15);
    });

    const maxActivity = Math.max(...hourActivity);
    const peakHours = hourActivity.map((count, hour) => ({
      hour,
      label: `${hour === 0 ? 12 : hour > 12 ? hour - 12 : hour}${hour < 12 ? 'AM' : 'PM'}`,
      activity: maxActivity > 0 ? Math.round((count / maxActivity) * 100) : 0,
      isPeak: count > 0 && count >= maxActivity * 0.7,
    }));

    const topPeakHours = peakHours
      .filter((h) => h.isPeak)
      .map((h) => h.label);

    res.json({ peakHours, topPeakHours });
  } catch (err) {
    next(err);
  }
};

// GET /api/insights/milestones
const getMilestones = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const [totalCompleted, focusSessions, streakDays] = await Promise.all([
      prisma.task.count({ where: { userId, isCompleted: true } }),
      prisma.focusSession.count({ where: { userId, completed: true } }),
      getCompletionStreak(userId),
    ]);

    const milestones = [];

    if (streakDays >= 5) {
      milestones.push({
        icon: 'auto_awesome',
        title: 'Deep Focus Streak',
        subtitle: `${streakDays} days of consistent deep work`,
        achieved: true,
      });
    }
    if (totalCompleted >= 24) {
      milestones.push({
        icon: 'check_circle',
        title: 'Inbox Zero',
        subtitle: `Cleared ${totalCompleted} tasks total`,
        achieved: true,
      });
    }
    if (focusSessions >= 10) {
      milestones.push({
        icon: 'timer',
        title: 'Focus Champion',
        subtitle: `Completed ${focusSessions} focus sessions`,
        achieved: true,
      });
    }

    // Next milestones
    if (streakDays < 7) {
      milestones.push({
        icon: 'local_fire_department',
        title: '7-Day Streak',
        subtitle: `${7 - streakDays} more days to go`,
        achieved: false,
        progress: (streakDays / 7) * 100,
      });
    }

    res.json({ milestones, stats: { totalCompleted, focusSessions, streakDays } });
  } catch (err) {
    next(err);
  }
};

async function getCompletionStreak(userId) {
  let streak = 0;
  const date = new Date();
  date.setHours(0, 0, 0, 0);

  for (let i = 0; i < 30; i++) {
    const dayStart = new Date(date);
    const dayEnd = new Date(date);
    dayEnd.setHours(23, 59, 59, 999);

    const count = await prisma.task.count({
      where: { userId, isCompleted: true, completedAt: { gte: dayStart, lte: dayEnd } },
    });

    if (count > 0) {
      streak++;
      date.setDate(date.getDate() - 1);
    } else {
      break;
    }
  }

  return streak;
}

module.exports = { getWeeklyInsights, getProductivityScore, getPeakHours, getMilestones };
