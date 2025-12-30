const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuration
const config = {
  jwtSecret: 'your-super-secret-jwt-key-change-this-in-production',
  jwtExpire: '7d',
  bcryptRounds: 12,
  dbName: 'login_system.db'
};

// Simple SQLite implementation (no external dependencies needed)
class SimpleDB {
  constructor(dbPath) {
    this.dbPath = dbPath;
    this.data = {
      users: [],
      sessions: [],
      loginAttempts: []
    };
    this.loadFromFile();
  }

  loadFromFile() {
    try {
      if (fs.existsSync(this.dbPath)) {
        const fileData = fs.readFileSync(this.dbPath, 'utf8');
        this.data = JSON.parse(fileData);
      }
    } catch (error) {
      console.log('Creating new database...');
      this.data = {
        users: [],
        sessions: [],
        loginAttempts: []
      };
    }
  }

  saveToFile() {
    try {
      fs.writeFileSync(this.dbPath, JSON.stringify(this.data, null, 2));
    } catch (error) {
      console.error('Error saving database:', error);
    }
  }

  generateId() {
    return Date.now() + Math.random().toString(36).substr(2, 9);
  }

  // User operations
  createUser(userData) {
    const user = {
      id: this.generateId(),
      username: userData.username,
      email: userData.email,
      password_hash: userData.password_hash,
      first_name: userData.first_name || null,
      last_name: userData.last_name || null,
      is_active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      last_login: null
    };

    this.data.users.push(user);
    this.saveToFile();
    return user;
  }

  findUserByEmail(email) {
    return this.data.users.find(user => user.email === email && user.is_active);
  }

  findUserByUsername(username) {
    return this.data.users.find(user => user.username === username && user.is_active);
  }

  findUserById(id) {
    return this.data.users.find(user => user.id == id && user.is_active);
  }

  updateUserLastLogin(userId) {
    const user = this.findUserById(userId);
    if (user) {
      user.last_login = new Date().toISOString();
      this.saveToFile();
    }
    return user;
  }

  emailExists(email) {
    return this.data.users.some(user => user.email === email);
  }

  usernameExists(username) {
    return this.data.users.some(user => user.username === username);
  }

  // Session operations
  createSession(sessionData) {
    const session = {
      id: this.generateId(),
      user_id: sessionData.user_id,
      token_hash: sessionData.token_hash,
      expires_at: sessionData.expires_at,
      created_at: new Date().toISOString(),
      ip_address: sessionData.ip_address,
      user_agent: sessionData.user_agent
    };

    this.data.sessions.push(session);
    this.saveToFile();
    return session;
  }

  deleteSession(tokenHash) {
    this.data.sessions = this.data.sessions.filter(session => session.token_hash !== tokenHash);
    this.saveToFile();
  }

  // Login attempts
  logLoginAttempt(email, ipAddress, success) {
    const attempt = {
      id: this.generateId(),
      email: email,
      ip_address: ipAddress,
      success: success,
      attempted_at: new Date().toISOString()
    };

    this.data.loginAttempts.push(attempt);
    this.saveToFile();
    return attempt;
  }

  getLoginAttempts(email = null, limit = 10) {
    let attempts = this.data.loginAttempts;

    if (email) {
      attempts = attempts.filter(attempt => attempt.email === email);
    }

    return attempts
      .sort((a, b) => new Date(b.attempted_at) - new Date(a.attempted_at))
      .slice(0, limit);
  }
}

// Initialize database
const db = new SimpleDB(path.join(__dirname, config.dbName));

// Rate limiting store
const rateLimitStore = {
  general: new Map(),
  auth: new Map(),
  register: new Map()
};

// Rate limiting middleware
const createRateLimit = (store, windowMs, max) => {
  return (req, res, next) => {
    const ip = req.ip || req.connection.remoteAddress;
    const now = Date.now();
    const windowStart = now - windowMs;

    // Clean old entries
    for (const [key, data] of store.entries()) {
      if (data.resetTime < now) {
        store.delete(key);
      }
    }

    const current = store.get(ip) || { count: 0, resetTime: now + windowMs };

    if (current.resetTime < now) {
      current.count = 1;
      current.resetTime = now + windowMs;
    } else {
      current.count++;
    }

    store.set(ip, current);

    if (current.count > max) {
      return res.status(429).json({
        success: false,
        message: 'Too many requests, please try again later'
      });
    }

    next();
  };
};

// Validation functions
const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

const validatePassword = (password) => {
  const minLength = 8;
  const hasUpper = /[A-Z]/.test(password);
  const hasLower = /[a-z]/.test(password);
  const hasNumber = /\d/.test(password);
  const hasSpecial = /[@$!%*?&]/.test(password);

  return password.length >= minLength && hasUpper && hasLower && hasNumber && hasSpecial;
};

const validateUsername = (username) => {
  const usernameRegex = /^[a-zA-Z0-9_]+$/;
  return username.length >= 3 && username.length <= 30 && usernameRegex.test(username);
};

// JWT utilities
const generateToken = (userId) => {
  return jwt.sign({ userId }, config.jwtSecret, { expiresIn: config.jwtExpire });
};

const verifyToken = (token) => {
  try {
    return jwt.verify(token, config.jwtSecret);
  } catch (error) {
    return null;
  }
};

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Access token required'
    });
  }

  const decoded = verifyToken(token);
  if (!decoded) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token'
    });
  }

  const user = db.findUserById(decoded.userId);
  if (!user) {
    return res.status(401).json({
      success: false,
      message: 'User not found'
    });
  }

  req.user = user;
  next();
};

// Utility functions
const createSessionHash = (token) => {
  return crypto.createHash('sha256').update(token).digest('hex');
};

const getUserProfile = (user) => {
  return {
    id: user.id,
    username: user.username,
    email: user.email,
    first_name: user.first_name,
    last_name: user.last_name,
    created_at: user.created_at,
    last_login: user.last_login
  };
};

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:3001', 'http://localhost:8080'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.set('trust proxy', 1);

// Apply rate limiting
app.use(createRateLimit(rateLimitStore.general, 15 * 60 * 1000, 100)); // 100 requests per 15 minutes

// Routes

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Login Backend API',
    version: '1.0.0',
    endpoints: {
      register: 'POST /api/auth/register',
      login: 'POST /api/auth/login',
      profile: 'GET /api/auth/profile',
      logout: 'POST /api/auth/logout',
      verifyToken: 'GET /api/auth/verify-token',
      loginAttempts: 'GET /api/auth/login-attempts',
      health: 'GET /api/auth/health'
    }
  });
});

// Register endpoint
app.post('/api/auth/register',
  createRateLimit(rateLimitStore.register, 60 * 60 * 1000, 3), // 3 per hour
  async (req, res) => {
    try {
      const { username, email, password, confirmPassword, first_name, last_name } = req.body;

      // Validation
      const errors = [];

      if (!username || !validateUsername(username)) {
        errors.push({ field: 'username', message: 'Username must be 3-30 characters and contain only letters, numbers, and underscores' });
      }

      if (!email || !validateEmail(email)) {
        errors.push({ field: 'email', message: 'Please provide a valid email address' });
      }

      if (!password || !validatePassword(password)) {
        errors.push({
          field: 'password',
          message: 'Password must be at least 8 characters with uppercase, lowercase, number and special character'
        });
      }

      if (password !== confirmPassword) {
        errors.push({ field: 'confirmPassword', message: 'Passwords do not match' });
      }

      if (first_name && (first_name.length < 2 || first_name.length > 50)) {
        errors.push({ field: 'first_name', message: 'First name must be 2-50 characters' });
      }

      if (last_name && (last_name.length < 2 || last_name.length > 50)) {
        errors.push({ field: 'last_name', message: 'Last name must be 2-50 characters' });
      }

      if (errors.length > 0) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors
        });
      }

      // Check if user exists
      if (db.emailExists(email)) {
        return res.status(409).json({
          success: false,
          message: 'Email already registered'
        });
      }

      if (db.usernameExists(username)) {
        return res.status(409).json({
          success: false,
          message: 'Username already taken'
        });
      }

      // Hash password
      const hashedPassword = await bcrypt.hash(password, config.bcryptRounds);

      // Create user
      const newUser = db.createUser({
        username,
        email,
        password_hash: hashedPassword,
        first_name,
        last_name
      });

      // Generate token
      const token = generateToken(newUser.id);

      console.log(`New user registered: ${email}`);

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: {
          user: getUserProfile(newUser),
          token
        }
      });

    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  });

// Login endpoint
app.post('/api/auth/login',
  createRateLimit(rateLimitStore.auth, 15 * 60 * 1000, 5), // 5 per 15 minutes
  async (req, res) => {
    try {
      const { email, password } = req.body;
      const clientIp = req.ip || req.connection.remoteAddress;
      const userAgent = req.get('User-Agent');

      // Validation
      if (!email || !validateEmail(email)) {
        return res.status(400).json({
          success: false,
          message: 'Please provide a valid email address'
        });
      }

      if (!password) {
        return res.status(400).json({
          success: false,
          message: 'Password is required'
        });
      }

      // Log login attempt (initially failed)
      db.logLoginAttempt(email, clientIp, false);

      // Find user
      const user = db.findUserByEmail(email);
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }

      // Verify password
      const isValidPassword = await bcrypt.compare(password, user.password_hash);
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }

      // Update last login
      db.updateUserLastLogin(user.id);

      // Log successful login
      db.logLoginAttempt(email, clientIp, true);

      // Generate token
      const token = generateToken(user.id);

      // Create session
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 7);

      db.createSession({
        user_id: user.id,
        token_hash: createSessionHash(token),
        expires_at: expiresAt.toISOString(),
        ip_address: clientIp,
        user_agent: userAgent
      });

      console.log(`User logged in: ${email}`);

      res.json({
        success: true,
        message: 'Login successful',
        data: {
          user: getUserProfile(user),
          token
        }
      });

    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  });

// Get profile endpoint
app.get('/api/auth/profile', authenticateToken, (req, res) => {
  try {
    res.json({
      success: true,
      data: {
        user: getUserProfile(req.user)
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Verify token endpoint
app.get('/api/auth/verify-token', authenticateToken, (req, res) => {
  try {
    res.json({
      success: true,
      message: 'Token is valid',
      data: {
        user: getUserProfile(req.user)
      }
    });
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Logout endpoint
app.post('/api/auth/logout', authenticateToken, (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
      const tokenHash = createSessionHash(token);
      db.deleteSession(tokenHash);
    }

    res.json({
      success: true,
      message: 'Logout successful'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get login attempts endpoint
app.get('/api/auth/login-attempts', authenticateToken, (req, res) => {
  try {
    const { email, limit = 10 } = req.query;
    const attempts = db.getLoginAttempts(email, parseInt(limit));

    res.json({
      success: true,
      data: attempts
    });
  } catch (error) {
    console.error('Get login attempts error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Health check endpoint
app.get('/api/auth/health', (req, res) => {
  res.json({
    success: true,
    message: 'Auth service is running',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Global error handler
app.use((error, req, res, next) => {
  console.error('Global error handler:', error);

  res.status(error.status || 500).json({
    success: false,
    message: error.message || 'Internal server error'
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Start server
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`✅ Database initialized: ${config.dbName}`);
  console.log(`✅ API available at: http://localhost:${PORT}`);
  console.log('\n📊 API Endpoints:');
  console.log('  POST /api/auth/register   - Register user');
  console.log('  POST /api/auth/login      - Login user');
  console.log('  GET  /api/auth/profile    - Get profile (protected)');
  console.log('  GET  /api/auth/verify-token - Verify token (protected)');
  console.log('  POST /api/auth/logout     - Logout (protected)');
  console.log('  GET  /api/auth/login-attempts - Login attempts (protected)');
  console.log('  GET  /api/auth/health     - Health check');
});

module.exports = app;