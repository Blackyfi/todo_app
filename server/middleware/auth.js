const { verifyToken } = require('../utils/encryption');
const { AuthenticationError } = require('../utils/errors');
const logger = require('../utils/logger');

/**
 * JWT Authentication Middleware
 */
function authenticate(req, res, next) {
  try {
    // Get token from Authorization header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AuthenticationError('No token provided');
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify token
    const decoded = verifyToken(token);

    if (!decoded) {
      throw new AuthenticationError('Invalid or expired token');
    }

    // Attach user info to request
    req.user = {
      user_id: decoded.user_id,
      username: decoded.username,
      device_id: decoded.device_id,
      is_admin: decoded.is_admin || false,
    };

    req.token = token;

    next();
  } catch (error) {
    if (error instanceof AuthenticationError) {
      logger.warn('Authentication failed', { error: error.message });
    }
    next(error);
  }
}

/**
 * Optional authentication (doesn't fail if no token)
 */
function optionalAuthenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const decoded = verifyToken(token);

      if (decoded) {
        req.user = {
          user_id: decoded.user_id,
          username: decoded.username,
          device_id: decoded.device_id,
          is_admin: decoded.is_admin || false,
        };
        req.token = token;
      }
    }

    next();
  } catch (error) {
    // Silently fail for optional auth
    next();
  }
}

/**
 * Admin-only middleware
 */
function requireAdmin(req, res, next) {
  if (!req.user || !req.user.is_admin) {
    return next(
      new AuthenticationError('Admin privileges required')
    );
  }
  next();
}

module.exports = {
  authenticate,
  optionalAuthenticate,
  requireAdmin,
};
