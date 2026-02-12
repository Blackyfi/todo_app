const express = require('express');
const router = express.Router();
const testController = require('../controllers/testController');
const asyncHandler = require('express-async-handler');

// Run tests endpoint (no auth for simplicity - add auth in production)
router.post('/run', asyncHandler(testController.runTests));

module.exports = router;
