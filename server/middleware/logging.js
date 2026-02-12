const morgan = require('morgan');
const logger = require('../utils/logger');
const { sanitizeForLogging } = require('../utils/helpers');

// Create a stream for morgan to write to winston
const stream = {
  write: (message) => {
    logger.info(message.trim());
  },
};

/**
 * HTTP request logger middleware
 */
const requestLogger = morgan(
  ':remote-addr - :remote-user [:date[clf]] ":method :url HTTP/:http-version" :status :res[content-length] ":referrer" ":user-agent" - :response-time ms',
  { stream }
);

/**
 * Log request body (for debugging in development)
 */
function logRequestBody(req, res, next) {
  if (process.env.NODE_ENV === 'development' && req.body && Object.keys(req.body).length > 0) {
    logger.debug('Request body', { body: sanitizeForLogging(req.body) });
  }
  next();
}

module.exports = {
  requestLogger,
  logRequestBody,
};
