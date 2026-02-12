/**
 * Validation helper functions
 */

/**
 * Validate username format
 */
function isValidUsername(username) {
  if (!username || typeof username !== 'string') return false;
  if (username.length < 3 || username.length > 30) return false;
  return /^[a-zA-Z0-9_]+$/.test(username);
}

/**
 * Validate email format
 */
function isValidEmail(email) {
  if (!email || typeof email !== 'string') return false;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Validate password strength
 */
function isValidPassword(password) {
  if (!password || typeof password !== 'string') return false;
  if (password.length < 8) return false;

  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);

  return hasUpperCase && hasLowerCase && hasNumber;
}

/**
 * Get password validation errors
 */
function getPasswordErrors(password) {
  const errors = [];

  if (!password || password.length < 8) {
    errors.push('Password must be at least 8 characters long');
  }
  if (!/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter');
  }
  if (!/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter');
  }
  if (!/[0-9]/.test(password)) {
    errors.push('Password must contain at least one number');
  }

  return errors;
}

/**
 * Validate device ID format
 */
function isValidDeviceId(deviceId) {
  if (!deviceId || typeof deviceId !== 'string') return false;
  return deviceId.length > 0 && deviceId.length <= 255;
}

/**
 * Validate Unix timestamp
 */
function isValidTimestamp(timestamp) {
  if (typeof timestamp !== 'number') return false;
  return timestamp >= 0 && timestamp <= 2147483647; // Max 32-bit int
}

module.exports = {
  isValidUsername,
  isValidEmail,
  isValidPassword,
  getPasswordErrors,
  isValidDeviceId,
  isValidTimestamp,
};
