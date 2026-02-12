const BaseModel = require('./base/BaseModel');
const { getCurrentTimestamp } = require('../utils/helpers');
const { ConflictError } = require('../utils/errors');

class Device extends BaseModel {
  constructor() {
    super('devices');
  }

  /**
   * Register or update device
   */
  registerDevice(userId, deviceId, deviceName, deviceType = null, appVersion = null, osVersion = null) {
    const existing = this.findByUserAndDeviceId(userId, deviceId);

    if (existing) {
      // Update existing device
      return this.updateDevice(existing.id, {
        device_name: deviceName,
        device_type: deviceType,
        app_version: appVersion,
        os_version: osVersion,
        last_seen_at: getCurrentTimestamp(),
      });
    } else {
      // Create new device
      return this.create({
        user_id: userId,
        device_id: deviceId,
        device_name: deviceName,
        device_type: deviceType,
        app_version: appVersion,
        os_version: osVersion,
        last_seen_at: getCurrentTimestamp(),
      });
    }
  }

  /**
   * Find device by user ID and device ID
   */
  findByUserAndDeviceId(userId, deviceId) {
    return this.findOneWhere('user_id = ? AND device_id = ?', [userId, deviceId]);
  }

  /**
   * Get all devices for user
   */
  findByUserId(userId) {
    return this.findWhere('user_id = ? AND is_active = 1', [userId]);
  }

  /**
   * Update device info
   */
  updateDevice(deviceId, data) {
    return this.update(deviceId, data);
  }

  /**
   * Update last seen timestamp
   */
  updateLastSeen(deviceId) {
    const query = `UPDATE ${this.tableName} SET last_seen_at = ? WHERE id = ?`;
    return this.exec(query, [getCurrentTimestamp(), deviceId]);
  }

  /**
   * Deactivate device
   */
  deactivateDevice(deviceId) {
    const query = `UPDATE ${this.tableName} SET is_active = 0, updated_at = ? WHERE id = ?`;
    return this.exec(query, [getCurrentTimestamp(), deviceId]);
  }

  /**
   * Get device statistics
   */
  getDeviceStats() {
    const totalDevices = this.count('is_active = 1');
    const twentyFourHoursAgo = getCurrentTimestamp() - 86400;
    const activeToday = this.count('is_active = 1 AND last_seen_at > ?', [twentyFourHoursAgo]);

    const byTypeQuery = `
      SELECT device_type, COUNT(*) as count
      FROM ${this.tableName}
      WHERE is_active = 1
      GROUP BY device_type
    `;
    const byType = this.query(byTypeQuery);

    const byTypeObj = {};
    byType.forEach((row) => {
      byTypeObj[row.device_type || 'unknown'] = row.count;
    });

    return {
      total: totalDevices,
      active_today: activeToday,
      by_type: byTypeObj,
    };
  }
}

module.exports = new Device();
