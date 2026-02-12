const BaseModel = require('./base/BaseModel');
const bcrypt = require('bcrypt');
const config = require('../config/app');
const { ConflictError, NotFoundError } = require('../utils/errors');
const { getCurrentTimestamp } = require('../utils/helpers');

class User extends BaseModel {
  constructor() {
    super('users');
  }

  /**
   * Create new user with hashed password
   */
  async createUser(username, password, email = null) {
    // Check if username exists
    const existing = this.findByUsername(username);
    if (existing) {
      throw new ConflictError('Username already exists');
    }

    // Check if email exists
    if (email) {
      const existingEmail = this.findByEmail(email);
      if (existingEmail) {
        throw new ConflictError('Email already exists');
      }
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, config.bcryptRounds);

    // Create user
    return this.create({
      username,
      email,
      password_hash: passwordHash,
    });
  }

  /**
   * Find user by username
   */
  findByUsername(username) {
    return this.findOneWhere('username = ?', [username]);
  }

  /**
   * Find user by email
   */
  findByEmail(email) {
    return this.findOneWhere('email = ?', [email]);
  }

  /**
   * Verify password
   */
  async verifyPassword(password, passwordHash) {
    return await bcrypt.compare(password, passwordHash);
  }

  /**
   * Update last login timestamp
   */
  updateLastLogin(userId) {
    const timestamp = getCurrentTimestamp();
    const query = `UPDATE ${this.tableName} SET last_login_at = ? WHERE id = ?`;
    return this.exec(query, [timestamp, userId]);
  }

  /**
   * Get active users count
   */
  getActiveUsersCount() {
    return this.count('is_active = 1');
  }

  /**
   * Get users who logged in recently
   */
  getRecentlyActiveUsers(sinceTimestamp) {
    return this.findWhere('last_login_at > ?', [sinceTimestamp]);
  }

  /**
   * Get new users since timestamp
   */
  getNewUsersSince(sinceTimestamp) {
    return this.findWhere('created_at > ?', [sinceTimestamp]);
  }

  /**
   * Deactivate user
   */
  deactivateUser(userId) {
    const query = `UPDATE ${this.tableName} SET is_active = 0, updated_at = ? WHERE id = ?`;
    return this.exec(query, [getCurrentTimestamp(), userId]);
  }

  /**
   * Get user statistics
   */
  getUserStats() {
    const totalUsers = this.count('is_active = 1');
    const twentyFourHoursAgo = getCurrentTimestamp() - 86400;
    const sevenDaysAgo = getCurrentTimestamp() - 604800;

    const activeToday = this.count('is_active = 1 AND last_login_at > ?', [twentyFourHoursAgo]);
    const newThisWeek = this.count('created_at > ?', [sevenDaysAgo]);

    return {
      total: totalUsers,
      active_today: activeToday,
      new_this_week: newThisWeek,
    };
  }
}

module.exports = new User();
