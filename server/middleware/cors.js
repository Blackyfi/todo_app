const cors = require('cors');
const config = require('../config/app');

/**
 * CORS middleware configuration
 */
const corsOptions = {
  origin: function (origin, callback) {
    const allowedOrigins = config.allowedOrigins;

    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) {
      return callback(null, true);
    }

    // Allow all origins if * is configured
    if (allowedOrigins.includes('*')) {
      return callback(null, true);
    }

    // Check if origin is in allowed list
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400, // 24 hours
};

module.exports = cors(corsOptions);
