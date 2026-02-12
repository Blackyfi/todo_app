module.exports = {
  secret: process.env.JWT_SECRET || 'change-this-secret-in-production',
  expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  algorithm: 'HS256',
};
