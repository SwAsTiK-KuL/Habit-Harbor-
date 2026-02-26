require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('./mongodb');
const admin = require('firebase-admin');

const app = express();
const PORT = process.env.PORT || 3000;


// ============================================
// FIREBASE ADMIN INIT
// ============================================

if (process.env.FIREBASE_PROJECT_ID) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId:   process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey:  process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    }),
  });
  console.log('✅ Firebase Admin initialized');
} else {
  console.warn('⚠️  Firebase not configured — push notifications disabled');
}


// ============================================
// CONFIG
// ============================================

const config = {
  jwtSecret:            process.env.JWT_SECRET            || 'fallback-dev-secret-key-never-use-in-production',
  refreshSecret:        process.env.REFRESH_SECRET        || 'fallback-refresh-secret-never-use-in-production',
  // ✅ Access token: 15 days  |  Refresh token: 90 days
  accessTokenExpire:    process.env.ACCESS_TOKEN_EXPIRE   || '15d',
  refreshTokenExpire:   process.env.REFRESH_TOKEN_EXPIRE  || '90d',
  refreshTokenExpireMs: 90 * 24 * 60 * 60 * 1000,         // 90 days in ms
  bcryptRounds:         parseInt(process.env.BCRYPT_ROUNDS) || 12,
};

if (process.env.NODE_ENV === 'production') {
  if (!process.env.JWT_SECRET || !process.env.REFRESH_SECRET) {
    console.warn('⚠️  WARNING: JWT_SECRET or REFRESH_SECRET not set in env!');
  } else {
    console.log('✅ Production security checks passed');
  }
}


// ============================================
// IST DATE/TIME HELPERS
// ============================================

const getISTDateString = () =>
  new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' });

const getISTHours = () =>
  parseInt(new Date().toLocaleString('en-US', { timeZone: 'Asia/Kolkata', hour: '2-digit', hour12: false }), 10);

const getISTMinutes = () =>
  parseInt(new Date().toLocaleString('en-US', { timeZone: 'Asia/Kolkata', minute: '2-digit' }), 10);

const addDaysIST = (dateStr, days) => {
  const [y, m, d] = dateStr.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d + days)).toISOString().split('T')[0];
};

const dateToISTString = (dateObj) =>
  new Date(dateObj).toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' });


// ============================================
// AUTO COMPLETION MANAGER
// ============================================

class AutoCompletionManager {
  constructor(db) {
    this.db = db;
    this.lastProcessedDate = null;
    this.isProcessing = false;
  }

  async loadLastProcessedDate() {
    const lastDate = await this.db.getMetadata('lastAutoCompletionDate');
    this.lastProcessedDate = lastDate;
    console.log(`📅 Last auto-completion: ${this.lastProcessedDate || 'Never'}`);
  }

  async saveLastProcessedDate(date) {
    await this.db.setMetadata('lastAutoCompletionDate', date);
    this.lastProcessedDate = date;
  }

  getYesterdayIST() {
    return addDaysIST(getISTDateString(), -1);
  }

  async processDate(dateStr) {
    console.log(`🕛 Processing auto-completion for ${dateStr} (IST)`);
    const allGoals = await this.db.getAllActiveGoals();
    let completedCount = 0;

    for (const goal of allGoals) {
      const goalCreatedDate = dateToISTString(goal.created_at);
      if (goalCreatedDate > dateStr) continue;

      const existingLog = await this.db.findGoalLog(goal.id, dateStr);
      if (!existingLog) {
        await this.db.createGoalLog({
          goal_id: goal.id,
          user_id: goal.user_id,
          status:  'completed',
          date:    dateStr,
          notes:   'Auto-marked as completed'
        });
        completedCount++;
      }
    }

    console.log(`✅ Processed ${dateStr}: ${completedCount} goals auto-completed`);
    return completedCount;
  }

  async processMissedDays() {
    const todayIST     = getISTDateString();
    const yesterdayIST = this.getYesterdayIST();

    if (this.lastProcessedDate === null) {
      await this.processDate(yesterdayIST);
      await this.saveLastProcessedDate(todayIST);
      return;
    }

    let currentDate = addDaysIST(this.lastProcessedDate, 1);
    while (currentDate <= yesterdayIST) {
      console.log(`📅 Catching up missed date (IST): ${currentDate}`);
      await this.processDate(currentDate);
      currentDate = addDaysIST(currentDate, 1);
    }

    await this.saveLastProcessedDate(todayIST);
  }

  async startScheduler() {
    console.log('🕛 Starting auto-completion scheduler...');
    await this.loadLastProcessedDate(); // ✅ Awaited

    setInterval(() => {
      if (this.isProcessing) return;
      const todayIST = getISTDateString();
      const hoursIST = getISTHours();

      if (this.lastProcessedDate !== todayIST && hoursIST === 0) {
        this.isProcessing = true;
        this.processMissedDays()
          .then(() => { this.isProcessing = false; })
          .catch((err) => { console.error('❌ Auto-completion error:', err); this.isProcessing = false; });
      }
    }, 3600000);

    setTimeout(() => {
      if (!this.isProcessing) {
        this.isProcessing = true;
        this.processMissedDays()
          .then(() => { this.isProcessing = false; })
          .catch((err) => { console.error('❌ Startup auto-completion error:', err); this.isProcessing = false; });
      }
    }, 5000);

    console.log('✅ Auto-completion scheduler initialized (IST)');
  }
}

const autoCompletionManager = new AutoCompletionManager(db);
autoCompletionManager.startScheduler().catch(console.error);


// ============================================
// NOTIFICATION SCHEDULER — 10 PM IST
// ============================================

class NotificationScheduler {
  constructor(db) {
    this.db = db;
    this.lastNotifiedDate = null;
  }

  start() {
    console.log('🔔 Notification scheduler started (fires at 22:00 IST)');

    setInterval(async () => {
      try {
        const todayIST   = getISTDateString();
        const hoursIST   = getISTHours();
        const minutesIST = getISTMinutes();

        if (hoursIST === 22 && minutesIST === 0 && this.lastNotifiedDate !== todayIST) {
          this.lastNotifiedDate = todayIST;
          console.log('🔔 10 PM IST — sending goal reminder notifications...');
          await this.sendReminderNotifications();
        }
      } catch (err) {
        console.error('❌ Notification scheduler error:', err);
      }
    }, 60 * 1000);
  }

  async sendReminderNotifications() {
    if (!admin.apps.length) {
      console.warn('⚠️  Firebase not initialized, skipping notifications');
      return;
    }

    const tokenDocs = await this.db.getUsersWithUnloggedGoalsToday();
    if (tokenDocs.length === 0) {
      console.log('✅ All users logged their goals — no notifications needed');
      return;
    }

    console.log(`📤 Sending notifications to ${tokenDocs.length} device(s)...`);
    const tokens = tokenDocs.map(doc => doc.fcm_token);
    const staleTokens = [];

    for (let i = 0; i < tokens.length; i += 500) {
      const batch = tokens.slice(i, i + 500);
      const message = {
        notification: {
          title: '🌟 Daily Check-In Reminder',
          body:  "Don't forget to log today's habit progress before midnight!",
        },
        android: {
          priority: 'high',
          notification: { channelId: 'habit_reminders', sound: 'default', clickAction: 'FLUTTER_NOTIFICATION_CLICK' },
        },
        data:   { type: 'daily_reminder', screen: 'home' },
        tokens: batch,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`✅ Sent: ${response.successCount} | Failed: ${response.failureCount}`);

      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const code = resp.error?.code;
          if (code === 'messaging/invalid-registration-token' ||
              code === 'messaging/registration-token-not-registered') {
            staleTokens.push(batch[idx]);
          }
        }
      });
    }

    if (staleTokens.length > 0) {
      console.log(`🧹 Removing ${staleTokens.length} stale FCM token(s)...`);
      for (const token of staleTokens) await this.db.deleteFCMToken(token);
    }
  }
}

const notificationScheduler = new NotificationScheduler(db);
notificationScheduler.start();


// ============================================
// CLEANUP SCHEDULER — daily at 3 AM IST
// Removes expired sessions & refresh tokens
// ============================================

setInterval(async () => {
  try {
    if (getISTHours() === 3 && getISTMinutes() === 0) {
      console.log('🧹 Running nightly cleanup...');
      await db.deleteExpiredSessions();
      await db.deleteExpiredRefreshTokens();
      console.log('✅ Nightly cleanup complete');
    }
  } catch (err) {
    console.error('❌ Cleanup scheduler error:', err);
  }
}, 60 * 1000);


// ============================================
// ANALYTICS HELPERS
// ============================================

const getDateRangeForPeriod = (period) => {
  const todayIST = getISTDateString();
  const [y, m]   = todayIST.split('-').map(Number);

  switch (period) {
    case 'month':
      return {
        start: `${y}-${String(m).padStart(2, '0')}-01`,
        end:   new Date(Date.UTC(y, m, 0)).toISOString().split('T')[0]
      };
    case 'quarter': {
      const q          = Math.floor((m - 1) / 3);
      const qStart     = q * 3 + 1;
      const qEnd       = qStart + 2;
      return {
        start: `${y}-${String(qStart).padStart(2, '0')}-01`,
        end:   new Date(Date.UTC(y, qEnd, 0)).toISOString().split('T')[0]
      };
    }
    case 'halfyear':
      return { start: addDaysIST(`${y}-${String(m).padStart(2, '0')}-01`, -150), end: todayIST };
    case 'year':
      return { start: `${y}-01-01`, end: todayIST };
    default:
      return {
        start: `${y}-${String(m).padStart(2, '0')}-01`,
        end:   new Date(Date.UTC(y, m, 0)).toISOString().split('T')[0]
      };
  }
};

const calculateStreaks = (logs) => {
  if (logs.length === 0) return { currentStreak: 0, longestStreak: 0 };

  const sortedLogs  = [...logs].sort((a, b) => new Date(b.date) - new Date(a.date));
  const todayIST    = getISTDateString();
  let currentStreak = 0;

  for (let i = 0; i < sortedLogs.length; i++) {
    const expected = addDaysIST(todayIST, -i);
    if (sortedLogs[i].date === expected && sortedLogs[i].status === 'completed') {
      currentStreak++;
    } else {
      break;
    }
  }

  const chronoLogs   = [...sortedLogs].reverse();
  let longestStreak  = 0;
  let tempStreak     = 0;

  for (let i = 0; i < chronoLogs.length; i++) {
    if (chronoLogs[i].status === 'completed') {
      if (i === 0) {
        tempStreak = 1;
      } else {
        const expectedNext = addDaysIST(chronoLogs[i - 1].date, 1);
        tempStreak = (chronoLogs[i].date === expectedNext) ? tempStreak + 1 : 1;
      }
      longestStreak = Math.max(longestStreak, tempStreak);
    } else {
      tempStreak = 0;
    }
  }

  return { currentStreak, longestStreak };
};


// ============================================
// RATE LIMITING
// ============================================

const rateLimitStore = { general: new Map(), auth: new Map(), register: new Map() };

const createRateLimit = (store, windowMs, max) => (req, res, next) => {
  const ip  = req.ip || req.connection.remoteAddress;
  const now = Date.now();

  for (const [key, data] of store.entries()) {
    if (data.resetTime < now) store.delete(key);
  }

  const current = store.get(ip) || { count: 0, resetTime: now + windowMs };
  if (current.resetTime < now) { current.count = 1; current.resetTime = now + windowMs; }
  else current.count++;

  store.set(ip, current);

  if (current.count > max) {
    return res.status(429).json({ success: false, message: 'Too many requests, please try again later' });
  }
  next();
};


// ============================================
// VALIDATION
// ============================================

const validateEmail    = (e) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e);
const validateUsername = (u) => u.length >= 3 && u.length <= 30 && /^[a-zA-Z0-9_]+$/.test(u);
const validatePassword = (p) =>
  p.length >= 8 && /[A-Z]/.test(p) && /[a-z]/.test(p) && /\d/.test(p) && /[@$!%*?&]/.test(p);


// ============================================
// JWT / TOKEN UTILITIES
// ============================================

// Short-lived access token (15d)
const generateAccessToken = (userId) =>
  jwt.sign({ userId, type: 'access' }, config.jwtSecret, { expiresIn: config.accessTokenExpire });

// Long-lived refresh token (90d) — random + signed
const generateRefreshToken = (userId) => {
  const raw   = crypto.randomBytes(64).toString('hex'); // raw token sent to client
  const token = jwt.sign({ userId, type: 'refresh', jti: raw }, config.refreshSecret, {
    expiresIn: config.refreshTokenExpire
  });
  return { token, raw };
};

const verifyAccessToken = (token) => {
  try {
    const decoded = jwt.verify(token, config.jwtSecret);
    if (decoded.type !== 'access') return null;
    return decoded;
  } catch {
    return null;
  }
};

const verifyRefreshTokenJWT = (token) => {
  try {
    const decoded = jwt.verify(token, config.refreshSecret);
    if (decoded.type !== 'refresh') return null;
    return decoded;
  } catch {
    return null;
  }
};

const hashToken = (token) =>
  crypto.createHash('sha256').update(token).digest('hex');


// ============================================
// AUTH MIDDLEWARE
// ============================================

// ✅ Validates JWT + confirms session exists in DB (prevents use of revoked tokens)
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token      = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Access token required' });
  }

  const decoded = verifyAccessToken(token);
  if (!decoded) {
    return res.status(401).json({ success: false, message: 'Invalid or expired token' });
  }

  // ✅ Check session still exists and isn't expired
  const sessionHash = hashToken(token);
  const session     = await db.findValidSession(sessionHash);
  if (!session) {
    return res.status(401).json({ success: false, message: 'Session expired. Please log in again.' });
  }

  const user = await db.findUserById(decoded.userId);
  if (!user) {
    return res.status(401).json({ success: false, message: 'User not found' });
  }

  req.user = user;
  next();
};


// ============================================
// MIDDLEWARE STACK
// ============================================

app.use(cors({
  origin:      process.env.FRONTEND_URL || ['http://localhost:3000', 'http://localhost:5173'],
  credentials: true
}));
app.use(express.json());

// ✅ Specific routes first
app.use('/api/auth/register', createRateLimit(rateLimitStore.register, 60 * 60 * 1000, 3));
app.use('/api/auth',          createRateLimit(rateLimitStore.auth,     15 * 60 * 1000, 10));
app.use('/api',               createRateLimit(rateLimitStore.general,  15 * 60 * 1000, 100));


// ============================================
// HEALTH & ROOT
// ============================================

app.get('/', (req, res) => {
  res.json({
    success: true, message: 'Habit Harbor API is running!',
    version: '2.1.0', timezone: 'IST (Asia/Kolkata)',
    currentISTDate: getISTDateString(),
    timestamp: new Date().toISOString()
  });
});

app.get('/api/health', (req, res) => {
  res.json({
    success: true, message: 'Habit Harbor API is running!',
    timezone: 'IST (Asia/Kolkata)', currentISTDate: getISTDateString(),
    timestamp: new Date().toISOString()
  });
});


// ============================================
// NOTIFICATION ROUTES
// ============================================

app.post('/api/notifications/register-token', authenticateToken, async (req, res) => {
  try {
    const { fcm_token } = req.body;
    if (!fcm_token) return res.status(400).json({ success: false, message: 'fcm_token is required' });
    await db.saveFCMToken(req.user.id, fcm_token);
    res.json({ success: true, message: 'FCM token registered' });
  } catch (error) {
    console.error('Register token error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/api/notifications/remove-token', authenticateToken, async (req, res) => {
  try {
    const { fcm_token } = req.body;
    if (!fcm_token) return res.status(400).json({ success: false, message: 'fcm_token is required' });
    await db.deleteFCMToken(fcm_token);
    res.json({ success: true, message: 'FCM token removed' });
  } catch (error) {
    console.error('Remove token error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/api/debug/send-test-notification', authenticateToken, async (req, res) => {
  if (process.env.NODE_ENV === 'production') {
    return res.status(403).json({ success: false, message: 'Forbidden in production' });
  }
  try {
    await notificationScheduler.sendReminderNotifications();
    res.json({ success: true, message: 'Test notification triggered' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});


// ============================================
// UTILITY
// ============================================

const getUserProfile = (user) => ({
  id: user.id, username: user.username, email: user.email,
  first_name: user.first_name, last_name: user.last_name,
  created_at: user.created_at, last_login: user.last_login
});

// Helper: create both tokens + store in DB
const issueTokenPair = async (userId, req) => {
  const accessToken  = generateAccessToken(userId);
  const { token: refreshToken } = generateRefreshToken(userId);

  const accessExpireMs  = 15 * 24 * 60 * 60 * 1000;  // 15 days
  const refreshExpireMs = config.refreshTokenExpireMs;  // 90 days

  // Store access token session
  await db.createSession({
    user_id:    userId,
    token_hash: hashToken(accessToken),
    expires_at: Date.now() + accessExpireMs,
    ip_address: req.ip,
    user_agent: req.headers['user-agent']
  });

  // Store refresh token
  await db.createRefreshToken({
    user_id:    userId,
    token_hash: hashToken(refreshToken),
    expires_at: Date.now() + refreshExpireMs,
    ip_address: req.ip,
    user_agent: req.headers['user-agent']
  });

  return { accessToken, refreshToken };
};


// ============================================
// AUTH ROUTES
// ============================================

app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, email, password, first_name, last_name } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({ success: false, message: 'Username, email, and password are required' });
    }
    if (!validateUsername(username)) {
      return res.status(400).json({ success: false, message: 'Username must be 3-30 chars, letters/numbers/underscores only' });
    }
    if (!validateEmail(email)) {
      return res.status(400).json({ success: false, message: 'Please provide a valid email address' });
    }
    if (!validatePassword(password)) {
      return res.status(400).json({ success: false, message: 'Password must be 8+ chars with uppercase, lowercase, number, and special character' });
    }
    if (await db.emailExists(email)) {
      return res.status(400).json({ success: false, message: 'Email already registered' });
    }
    if (await db.usernameExists(username)) {
      return res.status(400).json({ success: false, message: 'Username already taken' });
    }

    const password_hash = await bcrypt.hash(password, config.bcryptRounds);
    const user = await db.createUser({
      username, email, password_hash,
      first_name: first_name || null, last_name: last_name || null
    });

    await db.logLoginAttempt(email, req.ip, true);

    const { accessToken, refreshToken } = await issueTokenPair(user.id, req);

    res.status(201).json({
      success: true, message: 'User registered successfully',
      data: { user: getUserProfile(user), access_token: accessToken, refresh_token: refreshToken }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    const user = await db.findUserByEmail(email);
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      await db.logLoginAttempt(email, req.ip, false);
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    const updatedUser = await db.updateUserLastLogin(user.id);
    await db.logLoginAttempt(email, req.ip, true);

    const { accessToken, refreshToken } = await issueTokenPair(user.id, req);

    res.json({
      success: true, message: 'Login successful',
      data: { user: getUserProfile(updatedUser), access_token: accessToken, refresh_token: refreshToken }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// ============================================
// ✅ REFRESH TOKEN ENDPOINT
// Flutter calls this when access token is near
// expiry — silently issues a new token pair.
// ============================================
app.post('/api/auth/refresh', async (req, res) => {
  try {
    const { refresh_token } = req.body;

    if (!refresh_token) {
      return res.status(400).json({ success: false, message: 'refresh_token is required' });
    }

    // 1. Verify JWT signature & expiry
    const decoded = verifyRefreshTokenJWT(refresh_token);
    if (!decoded) {
      return res.status(401).json({ success: false, message: 'Invalid or expired refresh token. Please log in again.' });
    }

    // 2. Check token exists in DB and is not revoked
    const storedToken = await db.findValidRefreshToken(hashToken(refresh_token));
    if (!storedToken) {
      return res.status(401).json({ success: false, message: 'Refresh token revoked. Please log in again.' });
    }

    // 3. Verify user still exists
    const user = await db.findUserById(decoded.userId);
    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }

    // 4. ✅ Token Rotation — revoke old refresh token, issue new pair
    await db.revokeRefreshToken(hashToken(refresh_token));
    const { accessToken, refreshToken: newRefreshToken } = await issueTokenPair(user.id, req);

    console.log(`🔄 Token refreshed for user ${user.email}`);

    res.json({
      success: true, message: 'Token refreshed successfully',
      data: { access_token: accessToken, refresh_token: newRefreshToken }
    });

  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.get('/api/auth/profile', authenticateToken, async (req, res) => {
  res.json({ success: true, data: getUserProfile(req.user) });
});

app.get('/api/auth/verify-token', authenticateToken, async (req, res) => {
  res.json({ success: true, message: 'Token is valid', data: getUserProfile(req.user) });
});

// ✅ Logout: revoke BOTH tokens + all sessions
app.post('/api/auth/logout', authenticateToken, async (req, res) => {
  try {
    const authHeader    = req.headers['authorization'];
    const accessToken   = authHeader && authHeader.split(' ')[1];
    const { refresh_token } = req.body; // Flutter should send this too

    // Revoke access token session
    if (accessToken) await db.deleteSession(hashToken(accessToken));

    // Revoke refresh token if provided
    if (refresh_token) await db.revokeRefreshToken(hashToken(refresh_token));

    res.json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// ✅ Logout from ALL devices
app.post('/api/auth/logout-all', authenticateToken, async (req, res) => {
  try {
    await db.deleteAllUserSessions(req.user.id);
    await db.revokeAllUserRefreshTokens(req.user.id);
    res.json({ success: true, message: 'Logged out from all devices' });
  } catch (error) {
    console.error('Logout all error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});


// ============================================
// GOAL ROUTES
// ============================================

app.get('/api/goals', authenticateToken, async (req, res) => {
  try {
    const goals = await db.getGoalsByUserId(req.user.id);
    res.json({ success: true, data: goals });
  } catch (error) {
    console.error('Get goals error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/api/goals', authenticateToken, async (req, res) => {
  try {
    const { title, description, category, color, icon, target_frequency, target_count } = req.body;
    if (!title) return res.status(400).json({ success: false, message: 'Goal title is required' });

    const newGoal = await db.createGoal({
      user_id: req.user.id, title,
      description: description || '', category: category || 'General',
      color: color || '#4CAF50', icon: icon || 'star',
      target_frequency: target_frequency || 'daily', target_count: target_count || 1
    });

    res.status(201).json({ success: true, message: 'Goal created successfully', data: newGoal });
  } catch (error) {
    console.error('Create goal error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.get('/api/goals/:goalId', authenticateToken, async (req, res) => {
  try {
    const goal = await db.findGoalById(req.params.goalId);
    if (!goal || goal.user_id !== req.user.id) {
      return res.status(404).json({ success: false, message: 'Goal not found' });
    }
    res.json({ success: true, data: goal });
  } catch (error) {
    console.error('Get goal error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.put('/api/goals/:goalId', authenticateToken, async (req, res) => {
  try {
    const { goalId } = req.params;
    const updates = { ...req.body };
    delete updates.user_id; delete updates.created_at; delete updates.id;

    const existingGoal = await db.findGoalById(goalId);
    if (!existingGoal || existingGoal.user_id !== req.user.id) {
      return res.status(404).json({ success: false, message: 'Goal not found' });
    }

    const updatedGoal = await db.updateGoal(goalId, updates);
    res.json({ success: true, message: 'Goal updated successfully', data: updatedGoal });
  } catch (error) {
    console.error('Update goal error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.delete('/api/goals/:goalId', authenticateToken, async (req, res) => {
  try {
    const deleted = await db.deleteGoal(req.params.goalId, req.user.id);
    if (!deleted) return res.status(404).json({ success: false, message: 'Goal not found' });
    res.json({ success: true, message: 'Goal deleted successfully' });
  } catch (error) {
    console.error('Delete goal error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.get('/api/goals/:goalId/stats', authenticateToken, async (req, res) => {
  try {
    const { goalId } = req.params;
    const { days = 30 } = req.query;

    const goal = await db.findGoalById(goalId);
    if (!goal || goal.user_id !== req.user.id) {
      return res.status(404).json({ success: false, message: 'Goal not found' });
    }

    const logs      = await db.getGoalLogsByGoalId(goalId, parseInt(days));
    const completed = logs.filter(l => l.status === 'completed').length;
    const missed    = logs.filter(l => l.status === 'missed').length;
    const holiday   = logs.filter(l => l.status === 'holiday').length;
    const sick      = logs.filter(l => l.status === 'sick').length;
    const skipped   = logs.filter(l => l.status === 'skipped').length;
    const totalDays = parseInt(days);

    res.json({
      success: true,
      data: {
        total_days: totalDays, completed, missed, holiday, sick, skipped,
        completion_rate: totalDays > 0 ? Math.round((completed / totalDays) * 100) : 0,
        current_streak: 0, longest_streak: 0
      }
    });
  } catch (error) {
    console.error('Get goal stats error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// ✅ Duplicate guard + IST date fallback
app.post('/api/goals/:goalId/logs', authenticateToken, async (req, res) => {
  try {
    const { goalId }        = req.params;
    const { status, date, notes } = req.body;

    const goal = await db.findGoalById(goalId);
    if (!goal || goal.user_id !== req.user.id) {
      return res.status(404).json({ success: false, message: 'Goal not found' });
    }
    if (!status) return res.status(400).json({ success: false, message: 'Status is required' });

    const validStatuses = ['completed', 'missed', 'holiday', 'sick', 'skipped'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    const logDate = date || getISTDateString(); // ✅ IST

    const existingLog = await db.findGoalLog(goalId, logDate);
    if (existingLog) {
      return res.status(409).json({
        success: false,
        message: `Goal already logged as "${existingLog.status}" for ${logDate}`
      });
    }

    const newLog = await db.createGoalLog({
      goal_id: goalId, user_id: req.user.id,
      status, date: logDate, notes: notes || ''
    });

    res.status(201).json({ success: true, message: 'Goal logged successfully', data: newLog });
  } catch (error) {
    console.error('Log goal error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});


// ============================================
// ANALYTICS ROUTES
// ============================================

app.get('/api/analytics/overview', authenticateToken, async (req, res) => {
  try {
    const { period = 'month' } = req.query;
    const goals = await db.getGoalsByUserId(req.user.id);

    if (goals.length === 0) {
      return res.json({
        success: true,
        data: { totalGoals: 0, goals: [], stats: { completed: 0, missed: 0, holiday: 0, sick: 0, skipped: 0, completionRate: 0, unloggedDays: 0 } }
      });
    }

    const { start: startDate, end: endDate } = getDateRangeForPeriod(period);
    let totalCompleted = 0, totalMissed = 0, totalHoliday = 0, totalSick = 0, totalSkipped = 0, totalUnlogged = 0;

    for (const goal of goals) {
      const goalCreatedDate    = dateToISTString(goal.created_at);
      const effectiveStartDate = goalCreatedDate > startDate ? goalCreatedDate : startDate;
      const goalLogs           = await db.getGoalLogsByGoalId(goal.id, 1000);
      const periodLogs         = goalLogs.filter(l => l.date >= effectiveStartDate && l.date <= endDate);

      totalCompleted += periodLogs.filter(l => l.status === 'completed').length;
      totalMissed    += periodLogs.filter(l => l.status === 'missed').length;
      totalHoliday   += periodLogs.filter(l => l.status === 'holiday').length;
      totalSick      += periodLogs.filter(l => l.status === 'sick').length;
      totalSkipped   += periodLogs.filter(l => l.status === 'skipped').length;

      const [sy, sm, sd] = effectiveStartDate.split('-').map(Number);
      const [ey, em, ed] = endDate.split('-').map(Number);
      const effectiveDays = Math.floor((Date.UTC(ey, em - 1, ed) - Date.UTC(sy, sm - 1, sd)) / 86400000) + 1;
      totalUnlogged += Math.max(0, effectiveDays - periodLogs.length);
    }

    const completionRate = (totalCompleted + totalMissed) > 0
      ? Math.round((totalCompleted / (totalCompleted + totalMissed)) * 100) : 0;

    res.json({
      success: true,
      data: {
        totalGoals: goals.length,
        goals: goals.map(g => ({
          id: g.id, user_id: g.user_id, title: g.title, description: g.description,
          category: g.category, color: g.color, icon: g.icon,
          target_frequency: g.target_frequency, target_count: g.target_count,
          is_active: g.is_active, created_at: g.created_at.toISOString(),
          updated_at: g.updated_at.toISOString(), todayStatus: g.todayStatus, todayLogId: g.todayLogId
        })),
        stats: { completed: totalCompleted, missed: totalMissed, holiday: totalHoliday, sick: totalSick, skipped: totalSkipped, completionRate, unloggedDays: totalUnlogged }
      }
    });
  } catch (error) {
    console.error('Get overview analytics error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.get('/api/goals/:goalId/analytics', authenticateToken, async (req, res) => {
  try {
    const { goalId }         = req.params;
    const { period = 'month' } = req.query;

    const goal = await db.findGoalById(goalId);
    if (!goal || goal.user_id !== req.user.id) {
      return res.status(404).json({ success: false, message: 'Goal not found' });
    }

    const { start: startDate, end: endDate } = getDateRangeForPeriod(period);
    const goalCreatedDate    = dateToISTString(goal.created_at);
    const effectiveStartDate = goalCreatedDate > startDate ? goalCreatedDate : startDate;

    const allLogs    = await db.getGoalLogsByGoalId(goalId, 1000);
    const periodLogs = allLogs.filter(l => l.date >= effectiveStartDate && l.date <= endDate);

    const completed = periodLogs.filter(l => l.status === 'completed').length;
    const missed    = periodLogs.filter(l => l.status === 'missed').length;
    const holiday   = periodLogs.filter(l => l.status === 'holiday').length;
    const sick      = periodLogs.filter(l => l.status === 'sick').length;
    const skipped   = periodLogs.filter(l => l.status === 'skipped').length;

    const [sy, sm, sd] = effectiveStartDate.split('-').map(Number);
    const [ey, em, ed] = endDate.split('-').map(Number);
    const totalDays     = Math.floor((Date.UTC(ey, em - 1, ed) - Date.UTC(sy, sm - 1, sd)) / 86400000) + 1;
    const unloggedDays  = Math.max(0, totalDays - periodLogs.length);
    const completionRate = (completed + missed) > 0 ? Math.round((completed / (completed + missed)) * 100) : 0;

    const { currentStreak, longestStreak } = calculateStreaks(periodLogs);

    res.json({
      success: true,
      data: {
        stats: { completed, missed, holiday, sick, skipped, totalDays, completionRate, currentStreak, longestStreak, unloggedDays },
        logs: periodLogs.map(l => ({ date: l.date, status: l.status, notes: l.notes }))
      }
    });
  } catch (error) {
    console.error('Get goal analytics error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});


// ============================================
// DEBUG ENDPOINTS (dev only)
// ============================================

app.post('/api/debug/auto-complete-yesterday', authenticateToken, async (req, res) => {
  if (process.env.NODE_ENV === 'production') {
    return res.status(403).json({ success: false, message: 'Forbidden in production' });
  }
  try {
    const yesterdayStr = addDaysIST(getISTDateString(), -1);
    const allGoals     = await db.getAllActiveGoals();
    let autoCompletedCount = 0;

    for (const goal of allGoals) {
      const goalCreatedDate = dateToISTString(goal.created_at);
      if (goalCreatedDate > yesterdayStr) continue;
      const existingLog = await db.findGoalLog(goal.id, yesterdayStr);
      if (existingLog) continue;

      await db.createGoalLog({
        goal_id: goal.id, user_id: goal.user_id,
        status: 'completed', date: yesterdayStr, notes: 'Auto-marked as Completed'
      });
      autoCompletedCount++;
    }

    res.json({
      success: true,
      message: `Auto-completed ${autoCompletedCount} goals for ${yesterdayStr} (IST)`,
      data: { date: yesterdayStr, completedCount: autoCompletedCount, totalGoals: allGoals.length }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Auto-completion failed', error: error.message });
  }
});


// ============================================
// GLOBAL ERROR HANDLER
// ============================================

app.use((error, req, res, next) => {
  console.error('Global error handler:', error);
  res.status(error.status || 500).json({ success: false, message: error.message || 'Internal server error' });
});


// ============================================
// GRACEFUL SHUTDOWN
// ============================================

process.on('SIGTERM', async () => { await db.close(); process.exit(0); });
process.on('SIGINT',  async () => { await db.close(); process.exit(0); });
process.on('uncaughtException',   (err) => { console.error('Uncaught Exception:', err); process.exit(1); });
process.on('unhandledRejection',  (r, p) => { console.error('Unhandled Rejection:', p, r); process.exit(1); });


// ============================================
// START SERVER
// ============================================

app.listen(PORT, async () => {
  try {
    await db.connect();
    console.log(`✅ Server running on port ${PORT}`);
    console.log(`✅ Timezone: IST (Asia/Kolkata) | Today: ${getISTDateString()}`);
    console.log(`✅ Access token: ${config.accessTokenExpire} | Refresh token: ${config.refreshTokenExpire}`);
    console.log(`✅ API available at: http://localhost:${PORT}`);
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
});

module.exports = app;