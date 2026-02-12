module.exports = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT) || 8443,
  host: process.env.HOST || '0.0.0.0',

  // Security
  bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS) || 12,
  allowedOrigins: process.env.ALLOWED_ORIGINS
    ? process.env.ALLOWED_ORIGINS.split(',').map(origin => origin.trim())
    : ['*'],

  // Dashboard
  dashboardPort: parseInt(process.env.DASHBOARD_PORT) || 3000,
  dashboardEnabled: process.env.DASHBOARD_ENABLED === 'true',

  // Rate limiting
  rateLimits: {
    auth: {
      windowMs: parseInt(process.env.AUTH_RATE_LIMIT_WINDOW || 15) * 60 * 1000,
      max: parseInt(process.env.AUTH_RATE_LIMIT_MAX || 5),
    },
    api: {
      windowMs: parseInt(process.env.API_RATE_LIMIT_WINDOW || 1) * 60 * 1000,
      max: parseInt(process.env.API_RATE_LIMIT_MAX || 30),
    },
    sync: {
      windowMs: parseInt(process.env.SYNC_RATE_LIMIT_WINDOW || 1) * 60 * 1000,
      max: parseInt(process.env.SYNC_RATE_LIMIT_MAX || 10),
    },
  },
};
