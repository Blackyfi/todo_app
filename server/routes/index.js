const express = require('express');
const router = express.Router();

const authRoutes = require('./auth');
const syncRoutes = require('./sync');
const deviceRoutes = require('./devices');
const healthRoutes = require('./health');
const testRoutes = require('./test');

const { authLimiter, apiLimiter, syncLimiter } = require('../middleware/rateLimiter');

// Health check (no rate limiting)
router.use('/health', healthRoutes);

// Test routes (no rate limiting for development)
router.use('/test', testRoutes);

// Auth routes with strict rate limiting
router.use('/auth', authLimiter, authRoutes);

// Sync routes with moderate rate limiting
router.use('/sync', syncLimiter, syncRoutes);

// Device routes with general API rate limiting
router.use('/devices', apiLimiter, deviceRoutes);

module.exports = router;
