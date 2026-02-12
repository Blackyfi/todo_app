const User = require('../models/User');
const Device = require('../models/Device');
const ApiResponse = require('../utils/response');
const { AuthenticationError, ValidationError } = require('../utils/errors');
const { isValidUsername, isValidPassword, getPasswordErrors } = require('../utils/validation');
const { generateToken } = require('../utils/encryption');
const { getCurrentTimestamp, daysToSeconds } = require('../utils/helpers');
const logger = require('../utils/logger');

/**
 * Register new user
 */
async function register(req, res, next) {
  try {
    const { username, email, password } = req.body;

    // Validate inputs
    if (!isValidUsername(username)) {
      throw new ValidationError(
        'Username must be 3-30 characters and contain only letters, numbers, and underscores'
      );
    }

    const passwordErrors = getPasswordErrors(password);
    if (passwordErrors.length > 0) {
      throw new ValidationError(passwordErrors.join('. '));
    }

    // Create user
    const user = await User.createUser(username, password, email);

    logger.info('User registered successfully', { userId: user.id, username: user.username });

    return ApiResponse.created(
      res,
      {
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          created_at: user.created_at,
        },
      },
      'User registered successfully'
    );
  } catch (error) {
    next(error);
  }
}

/**
 * Login user
 */
async function login(req, res, next) {
  try {
    const { username, password, device_id, device_name, device_type, app_version, os_version } =
      req.body;

    // Validate inputs
    if (!username || !password) {
      throw new ValidationError('Username and password are required');
    }

    if (!device_id || !device_name) {
      throw new ValidationError('Device information is required');
    }

    // Find user
    const user = User.findByUsername(username);
    if (!user) {
      logger.warn('Login attempt with non-existent username', { username });
      throw new AuthenticationError('Invalid username or password');
    }

    // Verify password
    const isValidPassword = await User.verifyPassword(password, user.password_hash);
    if (!isValidPassword) {
      logger.warn('Login attempt with incorrect password', { userId: user.id, username });
      throw new AuthenticationError('Invalid username or password');
    }

    // Register or update device
    const device = Device.registerDevice(
      user.id,
      device_id,
      device_name,
      device_type,
      app_version,
      os_version
    );

    // Update last login
    User.updateLastLogin(user.id);

    // Generate JWT token
    const tokenPayload = {
      user_id: user.id,
      username: user.username,
      device_id: device_id,
      is_admin: user.is_admin,
    };

    const token = generateToken(tokenPayload);
    const expiresIn = 7; // days
    const expiresAt = getCurrentTimestamp() + daysToSeconds(expiresIn);

    logger.info('User logged in successfully', {
      userId: user.id,
      username: user.username,
      deviceId: device_id,
    });

    return ApiResponse.success(
      res,
      {
        token,
        expires_at: expiresAt,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
        },
        device: {
          id: device.id,
          device_id: device.device_id,
          device_name: device.device_name,
        },
      },
      'Login successful'
    );
  } catch (error) {
    next(error);
  }
}

/**
 * Refresh token
 */
async function refresh(req, res, next) {
  try {
    const { token } = req.body;

    if (!token) {
      throw new ValidationError('Token is required');
    }

    // Token verification happens in middleware
    // At this point, req.user is already set

    // Generate new token
    const tokenPayload = {
      user_id: req.user.user_id,
      username: req.user.username,
      device_id: req.user.device_id,
      is_admin: req.user.is_admin,
    };

    const newToken = generateToken(tokenPayload);
    const expiresIn = 7; // days
    const expiresAt = getCurrentTimestamp() + daysToSeconds(expiresIn);

    logger.info('Token refreshed successfully', { userId: req.user.user_id });

    return ApiResponse.success(
      res,
      {
        token: newToken,
        expires_at: expiresAt,
      },
      'Token refreshed successfully'
    );
  } catch (error) {
    next(error);
  }
}

/**
 * Logout user
 */
async function logout(req, res, next) {
  try {
    // In a stateless JWT system, logout is handled client-side
    // by discarding the token. We just log the event here.

    logger.info('User logged out', { userId: req.user.user_id });

    return ApiResponse.success(res, null, 'Logged out successfully');
  } catch (error) {
    next(error);
  }
}

module.exports = {
  register,
  login,
  refresh,
  logout,
};
