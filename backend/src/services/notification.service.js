const prisma = require('../config/database');

let firebaseAdmin = null;
try {
  const admin = require('firebase-admin');
  if (!admin.apps.length && process.env.FIREBASE_SERVICE_ACCOUNT) {
    admin.initializeApp({
      credential: admin.credential.cert(
        JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
      ),
    });
  }
  firebaseAdmin = admin;
} catch {
  console.warn('[Notifications] Firebase Admin not configured. Push disabled.');
}

const sendPush = async (fcmToken, title, body, data = {}) => {
  if (!firebaseAdmin || !fcmToken) return null;

  try {
    const result = await firebaseAdmin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
    return result;
  } catch (err) {
    console.error('[FCM Error]', err.message);
    return null;
  }
};

// Called by cron every minute to dispatch due reminders
const sendPendingReminders = async () => {
  const now = new Date();
  const oneMinuteLater = new Date(now.getTime() + 60000);

  const dueReminders = await prisma.reminder.findMany({
    where: {
      sent: false,
      remindAt: { gte: now, lte: oneMinuteLater },
    },
    include: {
      task: {
        include: { user: { select: { fcmToken: true } } },
      },
    },
  });

  for (const reminder of dueReminders) {
    const { task } = reminder;
    const { fcmToken } = task.user;

    await sendPush(
      fcmToken,
      `Reminder: ${task.title}`,
      task.dueDate
        ? `Due at ${new Date(task.dueDate).toLocaleTimeString()}`
        : 'Your task reminder',
      { taskId: task.id, type: 'reminder' }
    );

    // Save in-app notification
    await prisma.notification.create({
      data: {
        userId: task.userId,
        title: `Reminder: ${task.title}`,
        body: task.dueDate
          ? `Due at ${new Date(task.dueDate).toLocaleTimeString()}`
          : 'Your task reminder',
        type: 'reminder',
        data: { taskId: task.id },
      },
    });

    await prisma.reminder.update({
      where: { id: reminder.id },
      data: { sent: true },
    });
  }

  return dueReminders.length;
};

const sendOverloadAlert = async (userId, message) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { fcmToken: true },
  });

  await sendPush(
    user?.fcmToken,
    'Burnout Alert 💗',
    message,
    { type: 'overload' }
  );

  await prisma.notification.create({
    data: {
      userId,
      title: 'Burnout Alert',
      body: message,
      type: 'overload',
    },
  });
};

module.exports = { sendPush, sendPendingReminders, sendOverloadAlert };
