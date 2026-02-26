require('dotenv').config();
const { MongoClient, ObjectId } = require('mongodb');

class MongoDB {
  constructor() {
    this.client = null;
    this.db = null;
    this.isConnected = false;
  }

  async connect() {
    if (this.isConnected) {
      return this.db;
    }

    try {
      console.log('🔄 Connecting to MongoDB Atlas...');
      this.client = new MongoClient(process.env.MONGODB_URI);
      await this.client.connect();
      this.db = this.client.db('habit_harbor');
      this.isConnected = true;
      console.log('✅ MongoDB Atlas connected successfully!');
      return this.db;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  async close() {
    if (this.client) {
      await this.client.close();
      this.isConnected = false;
      console.log('✅ MongoDB connection closed');
    }
  }

  // ============================================
  // USER OPERATIONS
  // ============================================

  async createUser(userData) {
    const db = await this.connect();
    const user = {
      username:      userData.username,
      email:         userData.email,
      password_hash: userData.password_hash,
      first_name:    userData.first_name || null,
      last_name:     userData.last_name  || null,
      is_active:     true,
      created_at:    new Date(),
      updated_at:    new Date(),
      last_login:    null
    };

    const result = await db.collection('users').insertOne(user);
    user.id = result.insertedId.toString();
    console.log(`✅ User created: ${user.email}`);
    return user;
  }

  async findUserByEmail(email) {
    const db = await this.connect();
    const user = await db.collection('users').findOne({ email, is_active: true });
    if (user) user.id = user._id.toString();
    return user;
  }

  async findUserByUsername(username) {
    const db = await this.connect();
    const user = await db.collection('users').findOne({ username, is_active: true });
    if (user) user.id = user._id.toString();
    return user;
  }

  async findUserById(id) {
    const db = await this.connect();
    let query;
    try {
      query = { _id: new ObjectId(id), is_active: true };
    } catch {
      query = { id: id, is_active: true };
    }
    const user = await db.collection('users').findOne(query);
    if (user) user.id = user._id.toString();
    return user;
  }

  async updateUserLastLogin(userId) {
    const db = await this.connect();
    let query;
    try {
      query = { _id: new ObjectId(userId) };
    } catch {
      query = { id: userId };
    }
    await db.collection('users').updateOne(query, { $set: { last_login: new Date() } });
    return await this.findUserById(userId);
  }

  async emailExists(email) {
    const db = await this.connect();
    return (await db.collection('users').countDocuments({ email })) > 0;
  }

  async usernameExists(username) {
    const db = await this.connect();
    return (await db.collection('users').countDocuments({ username })) > 0;
  }

  // ============================================
  // SESSION OPERATIONS
  // ============================================

  async createSession(sessionData) {
    const db = await this.connect();
    const session = {
      user_id:    sessionData.user_id,
      token_hash: sessionData.token_hash,
      expires_at: new Date(sessionData.expires_at),
      created_at: new Date(),
      ip_address: sessionData.ip_address,
      user_agent: sessionData.user_agent
    };
    const result = await db.collection('sessions').insertOne(session);
    session.id = result.insertedId.toString();
    return session;
  }

  // ✅ NEW: Validate session exists and is not expired
  async findValidSession(tokenHash) {
    const db = await this.connect();
    const session = await db.collection('sessions').findOne({
      token_hash: tokenHash,
      expires_at: { $gt: new Date() }   // Must not be expired
    });
    return session;
  }

  async deleteSession(tokenHash) {
    const db = await this.connect();
    await db.collection('sessions').deleteOne({ token_hash: tokenHash });
  }

  // ✅ Delete all sessions for a user (force logout everywhere)
  async deleteAllUserSessions(userId) {
    const db = await this.connect();
    const result = await db.collection('sessions').deleteMany({ user_id: userId });
    console.log(`✅ Deleted ${result.deletedCount} session(s) for user ${userId}`);
  }

  // ✅ Clean up expired sessions (call periodically)
  async deleteExpiredSessions() {
    const db = await this.connect();
    const result = await db.collection('sessions').deleteMany({
      expires_at: { $lt: new Date() }
    });
    if (result.deletedCount > 0) {
      console.log(`🧹 Cleaned up ${result.deletedCount} expired session(s)`);
    }
  }

  // ============================================
  // ✅ REFRESH TOKEN OPERATIONS
  // ============================================

  async createRefreshToken(refreshData) {
    const db = await this.connect();
    const doc = {
      user_id:    refreshData.user_id,
      token_hash: refreshData.token_hash,   // SHA-256 of the raw refresh token
      expires_at: new Date(refreshData.expires_at),
      created_at: new Date(),
      ip_address: refreshData.ip_address,
      user_agent: refreshData.user_agent,
      is_revoked: false
    };
    const result = await db.collection('refresh_tokens').insertOne(doc);
    doc.id = result.insertedId.toString();
    return doc;
  }

  // Find a valid, non-revoked, non-expired refresh token
  async findValidRefreshToken(tokenHash) {
    const db = await this.connect();
    return await db.collection('refresh_tokens').findOne({
      token_hash: tokenHash,
      is_revoked: false,
      expires_at: { $gt: new Date() }
    });
  }

  // Revoke a specific refresh token (on logout or rotation)
  async revokeRefreshToken(tokenHash) {
    const db = await this.connect();
    await db.collection('refresh_tokens').updateOne(
      { token_hash: tokenHash },
      { $set: { is_revoked: true, revoked_at: new Date() } }
    );
  }

  // Revoke ALL refresh tokens for a user (force logout everywhere)
  async revokeAllUserRefreshTokens(userId) {
    const db = await this.connect();
    const result = await db.collection('refresh_tokens').updateMany(
      { user_id: userId, is_revoked: false },
      { $set: { is_revoked: true, revoked_at: new Date() } }
    );
    console.log(`✅ Revoked ${result.modifiedCount} refresh token(s) for user ${userId}`);
  }

  // Clean up old revoked/expired refresh tokens
  async deleteExpiredRefreshTokens() {
    const db = await this.connect();
    const result = await db.collection('refresh_tokens').deleteMany({
      $or: [
        { expires_at: { $lt: new Date() } },
        { is_revoked: true }
      ]
    });
    if (result.deletedCount > 0) {
      console.log(`🧹 Cleaned up ${result.deletedCount} stale refresh token(s)`);
    }
  }

  // ============================================
  // LOGIN ATTEMPTS
  // ============================================

  async logLoginAttempt(email, ipAddress, success) {
    const db = await this.connect();
    const attempt = {
      email,
      ip_address:   ipAddress,
      success,
      attempted_at: new Date()
    };
    await db.collection('login_attempts').insertOne(attempt);
    return attempt;
  }

  async getLoginAttempts(email = null, limit = 10) {
    const db = await this.connect();
    const query = email ? { email } : {};
    return await db.collection('login_attempts')
      .find(query)
      .sort({ attempted_at: -1 })
      .limit(limit)
      .toArray();
  }

  // ============================================
  // GOAL OPERATIONS
  // ============================================

  async createGoal(goalData) {
    const db = await this.connect();
    const goal = {
      user_id:          goalData.user_id,
      title:            goalData.title,
      description:      goalData.description      || '',
      category:         goalData.category         || 'General',
      color:            goalData.color            || '#4CAF50',
      icon:             goalData.icon             || 'star',
      target_frequency: goalData.target_frequency || 'daily',
      target_count:     goalData.target_count     || 1,
      is_active:        true,
      created_at:       new Date(),
      updated_at:       new Date()
    };
    const result = await db.collection('goals').insertOne(goal);
    goal.id = result.insertedId.toString();
    console.log(`✅ Goal created: ${goal.title} for user ${goal.user_id}`);
    return goal;
  }

  async getGoalsByUserId(userId) {
    const db = await this.connect();
    const goals = await db.collection('goals')
      .find({ user_id: userId, is_active: true })
      .toArray();

    const today = new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' });

    const enrichedGoals = await Promise.all(
      goals.map(async (goal) => {
        goal.id = goal._id.toString();
        const todayLog = await db.collection('goal_logs').findOne({
          goal_id: goal.id,
          date:    today
        });
        return {
          ...goal,
          todayStatus: todayLog ? todayLog.status           : null,
          todayLogId:  todayLog ? todayLog._id.toString()   : null
        };
      })
    );

    console.log(`📋 Retrieved ${enrichedGoals.length} goals for user ${userId}`);
    return enrichedGoals;
  }

  async findGoalById(goalId) {
    const db = await this.connect();
    let query;
    try {
      query = { _id: new ObjectId(goalId), is_active: true };
    } catch {
      query = { id: goalId, is_active: true };
    }
    const goal = await db.collection('goals').findOne(query);
    if (goal) goal.id = goal._id.toString();
    return goal;
  }

  async updateGoal(goalId, updates) {
    const db = await this.connect();
    let query;
    try {
      query = { _id: new ObjectId(goalId), is_active: true };
    } catch {
      query = { id: goalId, is_active: true };
    }
    const updateData = { ...updates, updated_at: new Date() };
    delete updateData.id;
    delete updateData._id;

    await db.collection('goals').updateOne(query, { $set: updateData });
    console.log(`✅ Goal updated: ${goalId}`);
    return await this.findGoalById(goalId);
  }

  async deleteGoal(goalId, userId) {
    const db = await this.connect();
    let query;
    try {
      query = { _id: new ObjectId(goalId), user_id: userId, is_active: true };
    } catch {
      query = { id: goalId, user_id: userId, is_active: true };
    }
    const result = await db.collection('goals').updateOne(
      query,
      { $set: { is_active: false, updated_at: new Date() } }
    );
    console.log(`✅ Goal deleted: ${goalId}`);
    return result.modifiedCount > 0;
  }

  // ============================================
  // GOAL LOG OPERATIONS
  // ============================================

  async createGoalLog(logData) {
    const db = await this.connect();
    const log = {
      goal_id:    logData.goal_id,
      user_id:    logData.user_id,
      date:       logData.date || new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' }),
      status:     logData.status,
      notes:      logData.notes || '',
      created_at: new Date(),
      updated_at: new Date()
    };
    const result = await db.collection('goal_logs').insertOne(log);
    log.id = result.insertedId.toString();
    console.log(`✅ Goal log created: ${log.status} for goal ${log.goal_id}`);
    return log;
  }

  async getGoalLogsByGoalId(goalId, limit = 30) {
    const db = await this.connect();
    const logs = await db.collection('goal_logs')
      .find({ goal_id: goalId })
      .sort({ date: -1 })
      .limit(limit)
      .toArray();
    logs.forEach(log => { log.id = log._id.toString(); });
    return logs;
  }

  async getAllActiveGoals() {
    const db = await this.connect();
    const goals = await db.collection('goals')
      .find({ is_active: true })
      .toArray();
    goals.forEach(goal => { goal.id = goal._id.toString(); });
    return goals;
  }

  async findGoalLog(goalId, date) {
    const db = await this.connect();
    const log = await db.collection('goal_logs').findOne({ goal_id: goalId, date });
    if (log) log.id = log._id.toString();
    return log;
  }

  // ============================================
  // METADATA OPERATIONS
  // ============================================

  async getMetadata(key) {
    const db = await this.connect();
    const metadata = await db.collection('metadata').findOne({ key });
    return metadata ? metadata.value : null;
  }

  async setMetadata(key, value) {
    const db = await this.connect();
    await db.collection('metadata').updateOne(
      { key },
      { $set: { key, value, updated_at: new Date() } },
      { upsert: true }
    );
  }

  // ============================================
  // FCM TOKEN OPERATIONS
  // ============================================

  async saveFCMToken(userId, fcmToken) {
    const db = await this.connect();
    await db.collection('fcm_tokens').updateOne(
      { fcm_token: fcmToken },
      {
        $set:         { user_id: userId, fcm_token: fcmToken, updated_at: new Date() },
        $setOnInsert: { created_at: new Date() }
      },
      { upsert: true }
    );
    console.log(`✅ FCM token saved for user ${userId}`);
  }

  async deleteFCMToken(fcmToken) {
    const db = await this.connect();
    await db.collection('fcm_tokens').deleteOne({ fcm_token: fcmToken });
    console.log('✅ FCM token removed');
  }

  async getFCMTokensByUserId(userId) {
    const db = await this.connect();
    return await db.collection('fcm_tokens').find({ user_id: userId }).toArray();
  }

  async getUsersWithUnloggedGoalsToday() {
    const db = await this.connect();
    const today = new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' });

    const allGoals  = await db.collection('goals').find({ is_active: true }).toArray();
    const todayLogs = await db.collection('goal_logs').find({ date: today }).toArray();

    const loggedGoalIds  = new Set(todayLogs.map(l => l.goal_id.toString()));
    const unloggedUserIds = new Set();

    for (const goal of allGoals) {
      const createdDate = new Date(goal.created_at)
        .toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' });
      if (createdDate <= today && !loggedGoalIds.has(goal._id.toString())) {
        unloggedUserIds.add(goal.user_id);
      }
    }

    if (unloggedUserIds.size === 0) return [];

    return await db.collection('fcm_tokens').find({
      user_id: { $in: Array.from(unloggedUserIds) }
    }).toArray();
  }

}

const mongodb = new MongoDB();
module.exports = mongodb;