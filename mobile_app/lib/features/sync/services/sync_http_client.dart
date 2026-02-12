import 'dart:async' show TimeoutException;
import 'dart:convert' as convert;
import 'dart:io' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/common/constants/app_constants.dart'
    as app_constants;
import 'package:todo_app/features/sync/models/sync_response.dart'
    as sync_response;

/// HTTP client wrapper for all server API communication.
class SyncHttpClient {
  static final SyncHttpClient _instance = SyncHttpClient._internal();
  factory SyncHttpClient() => _instance;
  SyncHttpClient._internal();

  final LoggerService _logger = LoggerService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  String _baseUrl = '';
  bool _acceptSelfSigned = false;

  /// Configure the client with server details.
  void configure({required String baseUrl, bool acceptSelfSigned = false}) {
    _baseUrl = baseUrl;
    _acceptSelfSigned = acceptSelfSigned;
  }

  /// Store the API token securely.
  Future<void> saveToken(String token) => _secureStorage.write(
        key: app_constants.AppConstants.syncTokenKey, value: token,
      );

  /// Read the stored API token.
  Future<String?> getToken() => _secureStorage.read(
        key: app_constants.AppConstants.syncTokenKey,
      );

  /// Remove the stored API token.
  Future<void> clearToken() => _secureStorage.delete(
        key: app_constants.AppConstants.syncTokenKey,
      );

  /// Build common headers with optional auth token.
  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Create an [HttpClient] that optionally accepts self-signed certs.
  io.HttpClient _createIoClient() {
    final client = io.HttpClient();
    client.connectionTimeout = const Duration(
      seconds: app_constants.AppConstants.httpTimeoutSeconds,
    );
    if (_acceptSelfSigned) {
      client.badCertificateCallback = (_, __, ___) => true;
    }
    return client;
  }

  /// Perform a GET request.
  Future<sync_response.SyncResponse> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams);
    await _logger.logInfo('GET $uri');

    try {
      final ioClient = _createIoClient();
      final request = await ioClient.getUrl(uri);
      final headers = await _headers();
      headers.forEach((k, v) => request.headers.set(k, v));

      final ioResponse = await request.close().timeout(
        const Duration(
          seconds: app_constants.AppConstants.httpTimeoutSeconds,
        ),
      );
      return _processResponse(ioResponse);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Perform a POST request.
  Future<sync_response.SyncResponse> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
    int? timeoutSeconds,
  }) async {
    final uri = _buildUri(path);
    await _logger.logInfo('POST $uri');

    try {
      final ioClient = _createIoClient();
      final request = await ioClient.postUrl(uri);
      final headers = await _headers(auth: auth);
      headers.forEach((k, v) => request.headers.set(k, v));

      if (body != null) {
        request.write(convert.jsonEncode(body));
      }

      final timeout = timeoutSeconds ??
          app_constants.AppConstants.httpTimeoutSeconds;
      final ioResponse = await request.close().timeout(
        Duration(seconds: timeout),
      );
      return _processResponse(ioResponse);
    } catch (e) {
      return _handleError(e);
    }
  }

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse(_baseUrl);
    return base.replace(
      path: '/api$path',
      queryParameters: queryParams,
    );
  }

  Future<sync_response.SyncResponse> _processResponse(
    io.HttpClientResponse ioResponse,
  ) async {
    final body = await ioResponse.transform(convert.utf8.decoder).join();
    final statusCode = ioResponse.statusCode;
    await _logger.logInfo('Response: $statusCode (${body.length} bytes)');

    if (body.isEmpty) {
      return sync_response.SyncResponse(
        success: statusCode >= 200 && statusCode < 300,
        statusCode: statusCode,
      );
    }

    try {
      final json = convert.jsonDecode(body) as Map<String, dynamic>;
      return sync_response.SyncResponse.fromJson(json, statusCode);
    } catch (_) {
      return sync_response.SyncResponse.error(
        'Invalid server response',
        statusCode,
      );
    }
  }

  sync_response.SyncResponse _handleError(dynamic e) {
    if (e is io.SocketException) {
      _logger.logError('Network error', e);
      return sync_response.SyncResponse.error(
        app_constants.AppConstants.syncNetworkError,
        0,
      );
    }
    if (e is io.HandshakeException || e is io.TlsException) {
      _logger.logError('SSL error', e);
      return sync_response.SyncResponse.error(
        'SSL certificate error. Enable "Accept self-signed certificates" '
        'if using a self-hosted server.',
        0,
      );
    }
    if (e is TimeoutException || e.toString().contains('TimeoutException')) {
      _logger.logError('Timeout', e);
      return sync_response.SyncResponse.error(
        'Server did not respond in time. Try again later.',
        0,
      );
    }
    _logger.logError('HTTP error', e);
    return sync_response.SyncResponse.error(
      'Connection failed: ${e.runtimeType}',
      0,
    );
  }
}
