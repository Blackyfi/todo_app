const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const jwtConfig = require('../config/jwt');

/**
 * Generate JWT token
 */
function generateToken(payload) {
  return jwt.sign(payload, jwtConfig.secret, {
    expiresIn: jwtConfig.expiresIn,
    algorithm: jwtConfig.algorithm,
  });
}

/**
 * Verify JWT token
 */
function verifyToken(token) {
  try {
    return jwt.verify(token, jwtConfig.secret);
  } catch (error) {
    return null;
  }
}

/**
 * Decode JWT token without verification (for debugging)
 */
function decodeToken(token) {
  return jwt.decode(token);
}

/**
 * Hash token for storage
 */
function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

/**
 * Generate random secret
 */
function generateSecret(length = 64) {
  return crypto.randomBytes(length).toString('hex');
}

module.exports = {
  generateToken,
  verifyToken,
  decodeToken,
  hashToken,
  generateSecret,
};
