require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const cron = require('node-cron');

const authRoutes = require('./src/routes/auth.routes');
const taskRoutes = require('./src/routes/tasks.routes');
const aiRoutes = require('./src/routes/ai.routes');
const focusRoutes = require('./src/routes/focus.routes');
const insightsRoutes = require('./src/routes/insights.routes');
const notificationRoutes = require('./src/routes/notifications.routes');
const { errorHandler, notFound } = require('./src/middleware/errorHandler');
const { sendPendingReminders } = require('./src/services/notification.service');

const app = express();

// Security & logging
app.use(helmet());
app.use(morgan('dev'));
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, curl) and all localhost origins (Flutter web dev)
    if (!origin || origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1')) {
      return callback(null, true);
    }
    // Allow any explicitly listed production origin
    const allowed = process.env.ALLOWED_ORIGINS?.split(',').map(o => o.trim()) ?? [];
    if (allowed.includes(origin)) return callback(null, true);
    callback(new Error(`CORS blocked: ${origin}`));
  },
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Too many requests, please try again later.' },
});
app.use('/api/', limiter);

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { error: 'Too many auth attempts, please try again later.' },
});

// Routes
app.get('/health', (req, res) => res.json({ status: 'ok', service: 'TaskGuard AI' }));
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/focus', focusRoutes);
app.use('/api/insights', insightsRoutes);
app.use('/api/notifications', notificationRoutes);

// Error handling
app.use(notFound);
app.use(errorHandler);

// Cron: check and send due reminders every minute
cron.schedule('* * * * *', () => {
  sendPendingReminders().catch(console.error);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`TaskGuard AI Backend running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
