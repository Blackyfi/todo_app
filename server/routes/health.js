const express = require('express');
const router = express.Router();
const healthController = require('../controllers/healthController');
const asyncHandler = require('express-async-handler');

// Health check - no authentication required
router.get('/', asyncHandler(healthController.healthCheck));

module.exports = router;
