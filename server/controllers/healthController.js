const ApiResponse = require('../utils/response');
const { getCurrentTimestamp } = require('../utils/helpers');
const { getDatabase } = require('../database/connection');
const packageJson = require('../package.json');

/**
 * Health check endpoint
 */
async function healthCheck(req, res, next) {
  try {
    let dbStatus = 'disconnected';

    // Check database connection
    try {
      const db = getDatabase();
      db.prepare('SELECT 1').get();
      dbStatus = 'connected';
    } catch (error) {
      dbStatus = 'error';
    }

    return ApiResponse.success(res, {
      status: 'healthy',
      timestamp: getCurrentTimestamp(),
      uptime: Math.floor(process.uptime()),
      version: packageJson.version,
      database: dbStatus,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  healthCheck,
};
