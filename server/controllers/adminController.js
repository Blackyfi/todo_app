const os = require('os');
const fs = require('fs');
const User = require('../models/User');
const Device = require('../models/Device');
const Task = require('../models/Task');
const SyncMetadata = require('../models/SyncMetadata');
const ApiResponse = require('../utils/response');
const { formatBytes, formatUptime } = require('../utils/helpers');
const config = require('../config/database');

/**
 * Get dashboard statistics
 */
async function getDashboardStats(req, res, next) {
  try {
    // Server stats
    const serverStats = {
      uptime: formatUptime(Math.floor(process.uptime())),
      uptime_seconds: Math.floor(process.uptime()),
      memory_usage_mb: (process.memoryUsage().heapUsed / 1024 / 1024).toFixed(2),
      cpu_usage_percent: (os.loadavg()[0] * 10).toFixed(2),
      version: process.env.npm_package_version || '1.0.0',
    };

    // User stats
    const userStats = User.getUserStats();

    // Device stats
    const deviceStats = Device.getDeviceStats();

    // Sync stats
    const syncStats = SyncMetadata.getSyncStats();

    // Database stats
    const taskStats = Task.getTaskStats();
    let dbSize = 0;
    try {
      const stats = fs.statSync(config.dbPath);
      dbSize = (stats.size / (1024 * 1024)).toFixed(2);
    } catch (error) {
      // Ignore if database file doesn't exist yet
    }

    const databaseStats = {
      size_mb: parseFloat(dbSize),
      tasks_count: taskStats.total,
      completed_tasks_count: taskStats.completed,
      completion_rate: taskStats.completion_rate,
      categories_count: 0, // TODO: Add category stats
      shopping_lists_count: 0, // TODO: Add shopping list stats
    };

    return ApiResponse.success(res, {
      server: serverStats,
      users: userStats,
      devices: deviceStats,
      syncs: syncStats,
      database: databaseStats,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getDashboardStats,
};
