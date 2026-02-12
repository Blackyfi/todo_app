const express = require('express');
const router = express.Router();
const deviceController = require('../controllers/deviceController');
const { authenticate } = require('../middleware/auth');
const asyncHandler = require('express-async-handler');

// All device routes require authentication
router.use(authenticate);

router.get('/', asyncHandler(deviceController.getDevices));
router.delete('/:deviceId', asyncHandler(deviceController.unregisterDevice));

module.exports = router;
