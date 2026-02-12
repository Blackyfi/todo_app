const rateLimit = require('express-rate-limit');
const config = require('../config/app');
const ApiResponse = require('../utils/response');

/**
 * Rate limiter for authentication endpoints
 */
const authLimiter = rateLimit({
  windowMs: config.rateLimits.auth.windowMs,
  max: config.rateLimits.auth.max,
  message: 'Too many authentication attempts, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    ApiResponse.error(res, 'Too many authentication attempts, please try again later', 429);
  },
});

/**
 * Rate limiter for general API endpoints
 */
const apiLimiter = rateLimit({
  windowMs: config.rateLimits.api.windowMs,
  max: config.rateLimits.api.max,
  message: 'Too many requests, please slow down',
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    ApiResponse.error(res, 'Too many requests, please slow down', 429);
  },
});

/**
 * Rate limiter for sync endpoints
 */
const syncLimiter = rateLimit({
  windowMs: config.rateLimits.sync.windowMs,
  max: config.rateLimits.sync.max,
  message: 'Sync rate limit exceeded',
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    ApiResponse.error(res, 'Sync rate limit exceeded', 429);
  },
});

module.exports = {
  authLimiter,
  apiLimiter,
  syncLimiter,
};
