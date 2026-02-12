require('dotenv').config();
const https = require('https');
const fs = require('fs');
const express = require('express');
const helmet = require('helmet');
const compression = require('compression');
const path = require('path');

const config = require('./config/app');
const sslConfig = require('./config/ssl');
const logger = require('./utils/logger');
const { initializeDatabase } = require('./database/connection');
const { runMigrations } = require('./database/migrations/migration-runner');

const corsMiddleware = require('./middleware/cors');
const { requestLogger, logRequestBody } = require('./middleware/logging');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

const apiRoutes = require('./routes/index');
const adminRoutes = require('./routes/admin');

// Initialize Express app
const app = express();

// ============================================
// INITIALIZATION
// ============================================

logger.info('=== Todo Sync Server Starting ===');
logger.info(`Environment: ${config.env}`);
logger.info(`Port: ${config.port}`);

// Initialize database
try {
  initializeDatabase();
  runMigrations();
  logger.info('Database initialized successfully');
} catch (error) {
  logger.error('Failed to initialize database', { error: error.message });
  process.exit(1);
}

// ============================================
// MIDDLEWARE
// ============================================

// Security headers
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'", "'unsafe-inline'"], // Allow inline scripts for dashboard
        imgSrc: ["'self'", 'data:', 'https:'],
      },
    },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true,
    },
  })
);

// CORS
app.use(corsMiddleware);

// Compression
app.use(compression());

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
app.use(requestLogger);
if (config.env === 'development') {
  app.use(logRequestBody);
}

// ============================================
// ROUTES
// ============================================

// Serve dashboard static files
app.use(express.static(path.join(__dirname, 'public')));

// API routes
app.use('/api', apiRoutes);
app.use('/api/admin', adminRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Todo Sync Server</title>
      <style>
        body {
          font-family: system-ui, -apple-system, sans-serif;
          max-width: 800px;
          margin: 50px auto;
          padding: 20px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
        }
        .container {
          background: rgba(255, 255, 255, 0.1);
          backdrop-filter: blur(10px);
          border-radius: 12px;
          padding: 40px;
        }
        h1 { margin-top: 0; }
        a {
          color: #fbbf24;
          text-decoration: none;
        }
        a:hover { text-decoration: underline; }
        .endpoint {
          background: rgba(0, 0, 0, 0.2);
          padding: 10px;
          margin: 10px 0;
          border-radius: 6px;
          font-family: monospace;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 Todo Sync Server</h1>
        <p>REST API server for todo list synchronization</p>
        <h2>Quick Links</h2>
        <ul>
          <li><a href="/index.html">📊 Dashboard</a></li>
          <li><a href="/api/health">❤️ Health Check</a></li>
        </ul>
        <h2>API Endpoints</h2>
        <div class="endpoint">POST /api/auth/register</div>
        <div class="endpoint">POST /api/auth/login</div>
        <div class="endpoint">POST /api/sync/upload</div>
        <div class="endpoint">GET /api/sync/download</div>
        <div class="endpoint">GET /api/devices</div>
        <p style="margin-top: 30px; opacity: 0.8;">Version: 1.0.0</p>
      </div>
    </body>
    </html>
  `);
});

// 404 handler
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

// ============================================
// SERVER STARTUP
// ============================================

// Load SSL certificates
let httpsOptions;
try {
  httpsOptions = {
    key: fs.readFileSync(sslConfig.keyPath),
    cert: fs.readFileSync(sslConfig.certPath),
    ...sslConfig.options,
  };
  logger.info('SSL certificates loaded successfully');
} catch (error) {
  logger.error('Failed to load SSL certificates', { error: error.message });
  logger.info('Run: cd ssl && bash generate-cert.sh');
  process.exit(1);
}

// Create HTTPS server
const server = https.createServer(httpsOptions, app);

// Start server
server.listen(config.port, config.host, () => {
  logger.info(`HTTPS server running on https://${config.host}:${config.port}`);
  logger.info(`Dashboard: https://localhost:${config.port}/index.html`);
  logger.info(`Health check: https://localhost:${config.port}/api/health`);
  logger.info('=== Server Ready ===');

  if (config.env === 'development') {
    console.log('\n🚀 Todo Sync Server is running!');
    console.log(`📊 Dashboard: https://localhost:${config.port}/index.html`);
    console.log(`❤️  Health: https://localhost:${config.port}/api/health`);
    console.log('\nPress Ctrl+C to stop\n');
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

// Unhandled rejection handler
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection', { reason, promise });
});

// Uncaught exception handler
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception', { error: error.message, stack: error.stack });
  process.exit(1);
});

module.exports = app;
