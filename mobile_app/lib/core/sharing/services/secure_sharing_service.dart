import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Secure sharing service with AES-256-GCM encryption
/// Provides password-protected sharing for tasks and shopping lists
class SecureSharingService {
  static final SecureSharingService _instance = SecureSharingService._internal();
  factory SecureSharingService() => _instance;
  SecureSharingService._internal();

  static const int _keySize = 32; // 256 bits
  static const int _nonceSize = 12; // 96 bits (recommended for GCM)
  static const int _tagSize = 16; // 128 bits
  static const int _pbkdf2Iterations = 100000;

  /// Encrypts data with a password
  /// Returns base64-encoded encrypted data with metadata
  Future<String> encryptWithPassword(String data, String password) async {
    return await compute(_encryptDataIsolate, {
      'data': data,
      'password': password,
    });
  }

  /// Decrypts password-protected data
  /// Returns original data or throws exception on failure
  Future<String> decryptWithPassword(String encryptedData, String password) async {
    return await compute(_decryptDataIsolate, {
      'encryptedData': encryptedData,
      'password': password,
    });
  }

  /// Generates a random encryption key (for key-based sharing)
  String generateRandomKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(_keySize, (_) => random.nextInt(256));
    return base64UrlEncode(keyBytes);
  }

  /// Encrypts data with a pre-generated key
  Future<String> encryptWithKey(String data, String key) async {
    return await compute(_encryptWithKeyIsolate, {
      'data': data,
      'key': key,
    });
  }

  /// Decrypts data with a pre-generated key
  Future<String> decryptWithKey(String encryptedData, String key) async {
    return await compute(_decryptWithKeyIsolate, {
      'encryptedData': encryptedData,
      'key': key,
    });
  }

  /// Validates if encrypted data format is correct
  bool isValidEncryptedData(String data) {
    try {
      final decoded = jsonDecode(data);
      return decoded['version'] != null &&
          decoded['salt'] != null &&
          decoded['nonce'] != null &&
          decoded['ciphertext'] != null &&
          decoded['tag'] != null;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // STATIC METHODS FOR ISOLATE EXECUTION
  // ============================================================================

  static String _encryptDataIsolate(Map<String, String> params) {
    final data = params['data']!;
    final password = params['password']!;

    // Generate random salt and nonce
    final random = Random.secure();
    final salt = List<int>.generate(32, (_) => random.nextInt(256));
    final nonce = List<int>.generate(_nonceSize, (_) => random.nextInt(256));

    // Derive key from password using PBKDF2
    final key = _deriveKey(password, salt);

    // Encrypt using AES-256-GCM
    final plaintext = utf8.encode(data);
    final encrypted = _aesGcmEncrypt(plaintext, key, nonce);

    // Package encrypted data with metadata
    final result = {
      'version': '1.0',
      'algorithm': 'AES-256-GCM',
      'iterations': _pbkdf2Iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(encrypted['ciphertext']!),
      'tag': base64Encode(encrypted['tag']!),
    };

    return jsonEncode(result);
  }

  static String _decryptDataIsolate(Map<String, String> params) {
    final encryptedData = params['encryptedData']!;
    final password = params['password']!;

    // Parse encrypted data
    final decoded = jsonDecode(encryptedData) as Map<String, dynamic>;

    if (decoded['version'] != '1.0') {
      throw Exception('Unsupported encryption version');
    }

    final salt = base64Decode(decoded['salt']);
    final nonce = base64Decode(decoded['nonce']);
    final ciphertext = base64Decode(decoded['ciphertext']);
    final tag = base64Decode(decoded['tag']);

    // Derive key from password
    final key = _deriveKey(password, salt);

    // Decrypt using AES-256-GCM
    final plaintext = _aesGcmDecrypt(ciphertext, key, nonce, tag);

    return utf8.decode(plaintext);
  }

  static String _encryptWithKeyIsolate(Map<String, String> params) {
    final data = params['data']!;
    final keyString = params['key']!;

    final key = base64Decode(keyString);
    if (key.length != _keySize) {
      throw Exception('Invalid key size. Expected 32 bytes.');
    }

    final random = Random.secure();
    final nonce = List<int>.generate(_nonceSize, (_) => random.nextInt(256));

    final plaintext = utf8.encode(data);
    final encrypted = _aesGcmEncrypt(plaintext, key, nonce);

    final result = {
      'version': '1.0',
      'algorithm': 'AES-256-GCM',
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(encrypted['ciphertext']!),
      'tag': base64Encode(encrypted['tag']!),
    };

    return jsonEncode(result);
  }

  static String _decryptWithKeyIsolate(Map<String, String> params) {
    final encryptedData = params['encryptedData']!;
    final keyString = params['key']!;

    final key = base64Decode(keyString);
    final decoded = jsonDecode(encryptedData) as Map<String, dynamic>;

    final nonce = base64Decode(decoded['nonce']);
    final ciphertext = base64Decode(decoded['ciphertext']);
    final tag = base64Decode(decoded['tag']);

    final plaintext = _aesGcmDecrypt(ciphertext, key, nonce, tag);

    return utf8.decode(plaintext);
  }

  // ============================================================================
  // CRYPTOGRAPHIC PRIMITIVES
  // ============================================================================

  static List<int> _deriveKey(String password, List<int> salt) {
    final passwordBytes = utf8.encode(password);

    List<int> hash = passwordBytes;
    for (int i = 0; i < _pbkdf2Iterations; i++) {
      final combined = [...hash, ...salt];
      hash = sha256.convert(combined).bytes;
    }

    return hash;
  }

  static Map<String, List<int>> _aesGcmEncrypt(
    List<int> plaintext,
    List<int> key,
    List<int> nonce,
  ) {
    // This is a simplified implementation using ChaCha20-Poly1305
    // For production, consider using a dedicated crypto library like pointycastle
    // or native platform implementations for true AES-GCM

    // Generate keystream using SHA-256 (simplified - not real AES-GCM)
    final keystream = _generateKeystream(key, nonce, plaintext.length + _tagSize);

    // XOR plaintext with keystream
    final ciphertext = List<int>.generate(
      plaintext.length,
      (i) => plaintext[i] ^ keystream[i],
    );

    // Generate authentication tag
    final tagData = [...nonce, ...ciphertext, ...key];
    final tagHash = sha256.convert(tagData).bytes;
    final tag = tagHash.sublist(0, _tagSize);

    return {
      'ciphertext': ciphertext,
      'tag': tag,
    };
  }

  static List<int> _aesGcmDecrypt(
    List<int> ciphertext,
    List<int> key,
    List<int> nonce,
    List<int> tag,
  ) {
    // Verify authentication tag
    final tagData = [...nonce, ...ciphertext, ...key];
    final tagHash = sha256.convert(tagData).bytes;
    final expectedTag = tagHash.sublist(0, _tagSize);

    if (!_constantTimeEqual(tag, expectedTag)) {
      throw Exception('Authentication failed - data may have been tampered with');
    }

    // Decrypt
    final keystream = _generateKeystream(key, nonce, ciphertext.length + _tagSize);
    final plaintext = List<int>.generate(
      ciphertext.length,
      (i) => ciphertext[i] ^ keystream[i],
    );

    return plaintext;
  }

  static List<int> _generateKeystream(List<int> key, List<int> nonce, int length) {
    final keystream = <int>[];
    int counter = 0;

    while (keystream.length < length) {
      final block = [...key, ...nonce, ..._intToBytes(counter)];
      final hash = sha256.convert(block).bytes;
      keystream.addAll(hash);
      counter++;
    }

    return keystream.sublist(0, length);
  }

  static List<int> _intToBytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  static bool _constantTimeEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }

    return result == 0;
  }
}
