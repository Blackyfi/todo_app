/**
 * General utility helper functions
 */

/**
 * Get current Unix timestamp
 */
function getCurrentTimestamp() {
  return Math.floor(Date.now() / 1000);
}

/**
 * Convert days to seconds
 */
function daysToSeconds(days) {
  return days * 24 * 60 * 60;
}

/**
 * Format bytes to human readable size
 */
function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];

  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

/**
 * Format uptime to human readable string
 */
function formatUptime(seconds) {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);

  const parts = [];
  if (days > 0) parts.push(`${days}d`);
  if (hours > 0) parts.push(`${hours}h`);
  if (minutes > 0) parts.push(`${minutes}m`);

  return parts.join(' ') || '0m';
}

/**
 * Sanitize object for logging (remove sensitive fields)
 */
function sanitizeForLogging(obj) {
  const sensitiveFields = ['password', 'password_hash', 'token', 'secret'];
  const sanitized = { ...obj };

  for (const field of sensitiveFields) {
    if (sanitized[field]) {
      sanitized[field] = '[REDACTED]';
    }
  }

  return sanitized;
}

/**
 * Sleep for specified milliseconds (for testing/rate limiting)
 */
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

module.exports = {
  getCurrentTimestamp,
  daysToSeconds,
  formatBytes,
  formatUptime,
  sanitizeForLogging,
  sleep,
};
