const logger = require('../utils/logger');
const ApiResponse = require('../utils/response');
const { AppError } = require('../utils/errors');

/**
 * Global error handler middleware
 */
function errorHandler(err, req, res, next) {
  // Log error
  logger.error('Error occurred', {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    userId: req.user ? req.user.user_id : null,
  });

  // Operational errors (expected)
  if (err.isOperational) {
    return ApiResponse.error(res, err.message, err.statusCode);
  }

  // Programming or unknown errors
  if (process.env.NODE_ENV === 'development') {
    return ApiResponse.error(res, err.message, 500, { stack: err.stack });
  } else {
    // Don't leak error details in production
    return ApiResponse.error(res, 'An unexpected error occurred', 500);
  }
}

/**
 * 404 handler
 */
function notFoundHandler(req, res) {
  return ApiResponse.error(res, `Route not found: ${req.method} ${req.path}`, 404);
}

module.exports = {
  errorHandler,
  notFoundHandler,
};
