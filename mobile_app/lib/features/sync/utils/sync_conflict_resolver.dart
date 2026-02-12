import 'package:todo_app/core/logger/logger_service.dart';

/// Resolves conflicts between local and server data using last-write-wins.
///
/// Server timestamps are in Unix seconds; local timestamps are in
/// milliseconds since epoch. This utility handles the conversion.
class SyncConflictResolver {
  static final LoggerService _logger = LoggerService();

  /// Compare local and server records and return the winner.
  ///
  /// [localUpdatedAtMs] is the local updatedAt in milliseconds.
  /// [serverUpdatedAtSec] is the server updated_at in Unix seconds.
  /// Returns `true` if the server version should be kept.
  static bool serverWins(int? localUpdatedAtMs, int? serverUpdatedAtSec) {
    if (localUpdatedAtMs == null) return true;
    if (serverUpdatedAtSec == null) return false;

    // Convert server seconds to milliseconds for comparison
    final serverMs = serverUpdatedAtSec * 1000;
    return serverMs >= localUpdatedAtMs;
  }

  /// Merge a list of server entities into the local database.
  ///
  /// Returns a [MergeResult] with counts of each operation.
  static Future<MergeResult> mergeEntities({
    required List<Map<String, dynamic>> serverEntities,
    required Future<Map<String, dynamic>?> Function(int clientId) findLocal,
    required Future<void> Function(Map<String, dynamic>) insertLocal,
    required Future<void> Function(Map<String, dynamic>) updateLocal,
    required Future<void> Function(int) deleteLocal,
    required String entityType,
  }) async {
    var inserted = 0;
    var updated = 0;
    var deleted = 0;
    var skipped = 0;

    for (final serverEntity in serverEntities) {
      try {
        final clientId = serverEntity['client_id'] as int?;
        if (clientId == null) continue;

        final isDeleted = serverEntity['deleted'] == 1;
        final local = await findLocal(clientId);

        if (isDeleted) {
          if (local != null) {
            await deleteLocal(clientId);
            deleted++;
          }
          continue;
        }

        if (local == null) {
          await insertLocal(serverEntity);
          inserted++;
          continue;
        }

        final localUpdatedAt = local['updatedAt'] as int?;
        final serverUpdatedAt = serverEntity['updated_at'] as int?;

        if (serverWins(localUpdatedAt, serverUpdatedAt)) {
          await updateLocal(serverEntity);
          updated++;
        } else {
          skipped++;
        }
      } catch (e) {
        await _logger.logWarning(
          'Conflict merge error for $entityType: $e',
        );
        skipped++;
      }
    }

    await _logger.logInfo(
      '$entityType merge: +$inserted ~$updated -$deleted =$skipped',
    );
    return MergeResult(
      inserted: inserted,
      updated: updated,
      deleted: deleted,
      skipped: skipped,
    );
  }
}

/// Summary of a merge operation.
class MergeResult {
  final int inserted;
  final int updated;
  final int deleted;
  final int skipped;

  const MergeResult({
    this.inserted = 0,
    this.updated = 0,
    this.deleted = 0,
    this.skipped = 0,
  });

  int get total => inserted + updated + deleted;
}
