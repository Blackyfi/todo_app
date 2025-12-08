import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/share_data.dart';
import 'secure_sharing_service.dart';

/// High-level sharing manager that handles export, encryption, and sharing
class SharingManager {
  static final SharingManager _instance = SharingManager._internal();
  factory SharingManager() => _instance;
  SharingManager._internal();

  final _secureSharing = SecureSharingService();

  // ============================================================================
  // FILE-BASED SHARING
  // ============================================================================

  /// Export share data as encrypted file
  ///
  /// [shareData] - The data to share
  /// [password] - Optional password for encryption. If null, exports unencrypted
  /// [fileName] - Optional custom file name
  ///
  /// Returns the file path of exported file
  Future<String> exportToFile({
    required ShareData shareData,
    String? password,
    String? fileName,
  }) async {
    // Prepare the data
    String dataToExport;

    if (password != null && password.isNotEmpty) {
      // Encrypt the data
      final plainJson = shareData.toJsonString();
      final encrypted = await _secureSharing.encryptWithPassword(plainJson, password);
      dataToExport = encrypted;
    } else {
      // Export unencrypted
      dataToExport = shareData.toJsonString();
    }

    // Generate file name
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = password != null ? 'encrypted' : 'json';
    final defaultFileName = '${_getFilePrefix(shareData.type)}_$timestamp.$extension';
    final actualFileName = fileName ?? defaultFileName;

    // Write to temporary file
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$actualFileName';
    final file = File(filePath);

    if (password != null) {
      // For encrypted files, write the encrypted string
      await file.writeAsString(dataToExport);
    } else {
      // For unencrypted files, write formatted JSON
      await file.writeAsString(dataToExport);
    }

    return filePath;
  }

  /// Share via native share sheet
  ///
  /// [shareData] - The data to share
  /// [password] - Optional password for encryption
  /// [shareText] - Optional text to include in share
  Future<ShareResult> share({
    required ShareData shareData,
    String? password,
    String? shareText,
  }) async {
    final filePath = await exportToFile(
      shareData: shareData,
      password: password,
    );

    final file = XFile(filePath);
    final text = shareText ?? _getShareText(shareData, password != null);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [file],
        subject: text,
      ),
    );

    return result;
  }

  /// Import share data from file
  ///
  /// [filePath] - Path to the file to import
  /// [password] - Password if file is encrypted (will try to decrypt)
  ///
  /// Returns the ShareData or throws exception
  Future<ShareData> importFromFile({
    required String filePath,
    String? password,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final content = await file.readAsString();

    // Try to determine if encrypted
    final isEncrypted = _secureSharing.isValidEncryptedData(content);

    if (isEncrypted) {
      if (password == null || password.isEmpty) {
        throw Exception('Password required for encrypted file');
      }

      // Decrypt the content
      final decrypted = await _secureSharing.decryptWithPassword(content, password);
      return ShareData.fromJsonString(decrypted);
    } else {
      // Parse as plain JSON
      return ShareData.fromJsonString(content);
    }
  }

  /// Import share data from raw string content
  ///
  /// [content] - The raw content (JSON or encrypted)
  /// [password] - Password if content is encrypted
  Future<ShareData> importFromString({
    required String content,
    String? password,
  }) async {
    final isEncrypted = _secureSharing.isValidEncryptedData(content);

    if (isEncrypted) {
      if (password == null || password.isEmpty) {
        throw Exception('Password required for encrypted data');
      }

      final decrypted = await _secureSharing.decryptWithPassword(content, password);
      return ShareData.fromJsonString(decrypted);
    } else {
      return ShareData.fromJsonString(content);
    }
  }

  // ============================================================================
  // QR CODE SUPPORT
  // ============================================================================

  /// Generate QR code data (for use with qr_flutter package)
  ///
  /// [shareData] - The data to encode
  /// [password] - Optional password for encryption
  /// [useCompression] - Whether to compress data (recommended for large data)
  ///
  /// Returns string data for QR code generation
  /// Throws exception if data is too large for QR code
  Future<String> generateQrData({
    required ShareData shareData,
    String? password,
    bool useCompression = false,
  }) async {
    String data;

    if (password != null && password.isNotEmpty) {
      final plainJson = shareData.toJsonString();
      data = await _secureSharing.encryptWithPassword(plainJson, password);
    } else {
      data = shareData.toJsonString();
    }

    // QR codes have practical limits (about 3KB for reliable scanning)
    if (data.length > 2900) {
      throw Exception(
        'Data too large for QR code (${data.length} bytes). '
        'Maximum recommended size is 2900 bytes. '
        'Consider using file sharing instead.',
      );
    }

    return data;
  }

  /// Import data from scanned QR code
  ///
  /// [qrData] - The scanned QR code data
  /// [password] - Password if data is encrypted
  Future<ShareData> importFromQrCode({
    required String qrData,
    String? password,
  }) async {
    return await importFromString(content: qrData, password: password);
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Check if data can fit in a QR code
  Future<bool> canFitInQrCode({
    required ShareData shareData,
    String? password,
  }) async {
    try {
      await generateQrData(shareData: shareData, password: password);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Estimate the size of share data in bytes
  int estimateSize(ShareData shareData, {bool encrypted = false}) {
    final jsonString = shareData.toJsonString();
    if (encrypted) {
      // Encrypted data is roughly 30% larger due to base64 encoding + metadata
      return (jsonString.length * 1.3).round();
    }
    return jsonString.length;
  }

  /// Check if content is encrypted
  bool isEncrypted(String content) {
    return _secureSharing.isValidEncryptedData(content);
  }

  String _getFilePrefix(ShareDataType type) {
    switch (type) {
      case ShareDataType.task:
        return 'task';
      case ShareDataType.taskList:
        return 'tasks';
      case ShareDataType.allTasks:
        return 'all_tasks';
      case ShareDataType.shoppingList:
        return 'shopping_list';
      case ShareDataType.shoppingListWithItems:
        return 'shopping_list_items';
      case ShareDataType.allShoppingLists:
        return 'all_shopping_lists';
    }
  }

  String _getShareText(ShareData shareData, bool isEncrypted) {
    final prefix = isEncrypted ? '🔒 Encrypted' : '📋';
    return '$prefix ${shareData.description} from Todo App';
  }
}
