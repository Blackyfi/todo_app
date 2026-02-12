const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const asyncHandler = require('express-async-handler');

// Public routes
router.post('/register', asyncHandler(authController.register));
router.post('/login', asyncHandler(authController.login));
router.post('/refresh', authenticate, asyncHandler(authController.refresh));

// Protected routes
router.post('/logout', authenticate, asyncHandler(authController.logout));

module.exports = router;
