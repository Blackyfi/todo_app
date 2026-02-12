const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const asyncHandler = require('express-async-handler');

// Admin stats endpoint - no auth for now (add requireAdmin middleware in production)
router.get('/stats', asyncHandler(adminController.getDashboardStats));

module.exports = router;
