const Device = require('../models/Device');
const ApiResponse = require('../utils/response');
const { NotFoundError } = require('../utils/errors');
const logger = require('../utils/logger');

/**
 * Get all devices for authenticated user
 */
async function getDevices(req, res, next) {
  try {
    const userId = req.user.user_id;
    const devices = Device.findByUserId(userId);

    return ApiResponse.success(res, {
      devices,
      count: devices.length,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Unregister device (soft delete)
 */
async function unregisterDevice(req, res, next) {
  try {
    const userId = req.user.user_id;
    const { deviceId } = req.params;

    // Find device
    const device = Device.findByUserAndDeviceId(userId, deviceId);

    if (!device) {
      throw new NotFoundError('Device not found');
    }

    // Deactivate device
    Device.deactivateDevice(device.id);

    logger.info('Device unregistered', { userId, deviceId });

    return ApiResponse.success(res, null, 'Device unregistered successfully');
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getDevices,
  unregisterDevice,
};
