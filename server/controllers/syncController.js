const Task = require('../models/Task');
const Category = require('../models/Category');
const SyncMetadata = require('../models/SyncMetadata');
const Device = require('../models/Device');
const ApiResponse = require('../utils/response');
const { ValidationError} = require('../utils/errors');
const { getCurrentTimestamp } = require('../utils/helpers');
const { getDatabase } = require('../database/connection');
const logger = require('../utils/logger');

/**
 * Upload sync data from device
 */
async function upload(req, res, next) {
  try {
    const userId = req.user.user_id;
    const { device_id, sync_timestamp, data } = req.body;

    if (!device_id || !data) {
      throw new ValidationError('device_id and data are required');
    }

    // Update device last seen
    const device = Device.findByUserAndDeviceId(userId, device_id);
    if (device) {
      Device.updateLastSeen(device.id);
    }

    const stats = {
      uploaded: {},
      conflicts: {},
    };

    const db = getDatabase();

    // Process sync in transaction
    db.transaction(() => {
      // Process categories
      if (data.categories && Array.isArray(data.categories)) {
        stats.uploaded.categories = 0;
        stats.conflicts.categories = 0;

        data.categories.forEach((category) => {
          const result = Category.upsertCategory(userId, device_id, category);
          if (result.updated) {
            stats.uploaded.categories++;
          } else if (result.conflict) {
            stats.conflicts.categories++;
          }
        });

        SyncMetadata.updateSyncMetadata(userId, device_id, 'categories', 'success');
      }

      // Process tasks
      if (data.tasks && Array.isArray(data.tasks)) {
        stats.uploaded.tasks = 0;
        stats.conflicts.tasks = 0;

        data.tasks.forEach((task) => {
          const result = Task.upsertTask(userId, device_id, task);
          if (result.updated) {
            stats.uploaded.tasks++;
          } else if (result.conflict) {
            stats.conflicts.tasks++;
          }
        });

        SyncMetadata.updateSyncMetadata(userId, device_id, 'tasks', 'success');
      }

      // Add other entity types here (shopping_lists, notification_settings, etc.)
    })();

    logger.info('Sync upload completed', {
      userId,
      deviceId: device_id,
      stats,
    });

    return ApiResponse.success(
      res,
      {
        ...stats,
        sync_timestamp: getCurrentTimestamp(),
      },
      'Data uploaded successfully'
    );
  } catch (error) {
    logger.error('Sync upload failed', { error: error.message, userId: req.user.user_id });
    SyncMetadata.updateSyncMetadata(
      req.user.user_id,
      req.body.device_id,
      'upload',
      'failed',
      error.message
    );
    next(error);
  }
}

/**
 * Download sync data to device
 */
async function download(req, res, next) {
  try {
    const userId = req.user.user_id;
    const { device_id } = req.query;
    const sinceTimestamp = parseInt(req.query.since) || 0;

    if (!device_id) {
      throw new ValidationError('device_id query parameter is required');
    }

    // Update device last seen
    const device = Device.findByUserAndDeviceId(userId, device_id);
    if (device) {
      Device.updateLastSeen(device.id);
    }

    // Fetch all data or delta
    const data = {
      categories: [],
      tasks: [],
      notification_settings: [],
      shopping_lists: [],
      shopping_items: [],
      auto_delete_settings: null,
    };

    if (sinceTimestamp > 0) {
      // Delta sync - only changes since timestamp
      data.categories = Category.findUpdatedSince(userId, sinceTimestamp);
      data.tasks = Task.findUpdatedSince(userId, sinceTimestamp);
    } else {
      // Full sync - all data
      data.categories = Category.findByUserId(userId, true); // Include deleted
      data.tasks = Task.findByUserId(userId, true); // Include deleted
    }

    // Update sync metadata
    SyncMetadata.updateSyncMetadata(userId, device_id, 'download', 'success');

    logger.info('Sync download completed', {
      userId,
      deviceId: device_id,
      since: sinceTimestamp,
      categoriesCount: data.categories.length,
      tasksCount: data.tasks.length,
    });

    return ApiResponse.success(res, {
      ...data,
      sync_timestamp: getCurrentTimestamp(),
    });
  } catch (error) {
    logger.error('Sync download failed', { error: error.message, userId: req.user.user_id });
    SyncMetadata.updateSyncMetadata(
      req.user.user_id,
      req.query.device_id,
      'download',
      'failed',
      error.message
    );
    next(error);
  }
}

/**
 * Get sync status
 */
async function status(req, res, next) {
  try {
    const userId = req.user.user_id;
    const { device_id } = req.query;

    if (!device_id) {
      throw new ValidationError('device_id query parameter is required');
    }

    const syncStatus = SyncMetadata.getSyncStatus(userId, device_id);

    const statusObj = {};
    syncStatus.forEach((meta) => {
      statusObj[meta.entity_type] = {
        last_sync_at: meta.last_sync_at,
        status: meta.last_sync_status,
        sync_count: meta.sync_count,
        error_count: meta.error_count,
      };
    });

    return ApiResponse.success(res, {
      last_sync: statusObj,
      server_timestamp: getCurrentTimestamp(),
      pending_changes: false, // Could be calculated based on updated_at timestamps
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  upload,
  download,
  status,
};
