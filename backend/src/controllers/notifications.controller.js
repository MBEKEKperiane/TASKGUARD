const prisma = require('../config/database');

// POST /api/notifications/token
const saveFcmToken = async (req, res, next) => {
  try {
    const { token } = req.body;
    await prisma.user.update({
      where: { id: req.user.id },
      data: { fcmToken: token },
    });
    res.json({ message: 'FCM token saved.' });
  } catch (err) {
    next(err);
  }
};

// GET /api/notifications
const listNotifications = async (req, res, next) => {
  try {
    const { limit = 30, unreadOnly } = req.query;
    const where = { userId: req.user.id };
    if (unreadOnly === 'true') where.isRead = false;

    const notifications = await prisma.notification.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: Number(limit),
    });

    const unreadCount = await prisma.notification.count({
      where: { userId: req.user.id, isRead: false },
    });

    res.json({ notifications, unreadCount });
  } catch (err) {
    next(err);
  }
};

// PATCH /api/notifications/:id/read
const markRead = async (req, res, next) => {
  try {
    await prisma.notification.updateMany({
      where: { id: req.params.id, userId: req.user.id },
      data: { isRead: true },
    });
    res.json({ message: 'Notification marked as read.' });
  } catch (err) {
    next(err);
  }
};

// PATCH /api/notifications/read-all
const markAllRead = async (req, res, next) => {
  try {
    const { count } = await prisma.notification.updateMany({
      where: { userId: req.user.id, isRead: false },
      data: { isRead: true },
    });
    res.json({ message: `${count} notifications marked as read.` });
  } catch (err) {
    next(err);
  }
};

module.exports = { saveFcmToken, listNotifications, markRead, markAllRead };
