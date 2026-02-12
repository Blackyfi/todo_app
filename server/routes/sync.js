const express = require('express');
const router = express.Router();
const syncController = require('../controllers/syncController');
const { authenticate } = require('../middleware/auth');
const asyncHandler = require('express-async-handler');

// All sync routes require authentication
router.use(authenticate);

router.post('/upload', asyncHandler(syncController.upload));
router.get('/download', asyncHandler(syncController.download));
router.get('/status', asyncHandler(syncController.status));

module.exports = router;
