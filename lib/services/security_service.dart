import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

/// Service untuk secure storage dan encryption
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Encryption key (dalam production, ini harus di-generate secara aman)
  final _key = encrypt.Key.fromLength(32);
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  bool _isInitialized = false;

  /// Initialize security service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _iv = encrypt.IV.fromLength(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));

    _isInitialized = true;
  }

  /// Encrypt string
  String encryptString(String plainText) {
    if (!_isInitialized) {
      throw Exception('SecurityService not initialized');
    }
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypt string
  String decryptString(String encryptedText) {
    if (!_isInitialized) {
      throw Exception('SecurityService not initialized');
    }
    final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  /// Save secure data
  Future<void> saveSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Read secure data
  Future<String?> readSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Delete secure data
  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Delete all secure data
  Future<void> deleteAllSecure() async {
    await _secureStorage.deleteAll();
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    return await _secureStorage.containsKey(key: key);
  }

  /// Save encrypted data
  Future<void> saveEncrypted(String key, String value) async {
    final encrypted = encryptString(value);
    await saveSecure(key, encrypted);
  }

  /// Read encrypted data
  Future<String?> readEncrypted(String key) async {
    final encrypted = await readSecure(key);
    if (encrypted == null) return null;
    return decryptString(encrypted);
  }

  /// Save object as JSON (encrypted)
  Future<void> saveObject(String key, Map<String, dynamic> object) async {
    final jsonString = jsonEncode(object);
    await saveEncrypted(key, jsonString);
  }

  /// Read object from JSON (encrypted)
  Future<Map<String, dynamic>?> readObject(String key) async {
    final jsonString = await readEncrypted(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Get all keys
  Future<Map<String, String>> readAll() async {
    return await _secureStorage.readAll();
  }
}

/// Helper untuk common secure storage operations
class SecureStorageKeys {
  // Define your secure storage keys here
  static const String userCredentials = 'user_credentials';
  static const String apiToken = 'api_token';
  static const String encryptionKey = 'encryption_key';
  static const String appSettings = 'app_settings';
  static const String licenseKey = 'license_key';
}

/// Example usage:
/// 
/// // Initialize
/// await SecurityService().initialize();
/// 
/// // Save encrypted data
/// await SecurityService().saveEncrypted('password', 'mySecretPassword');
/// 
/// // Read encrypted data
/// final password = await SecurityService().readEncrypted('password');
/// 
/// // Save object
/// await SecurityService().saveObject('user', {
///   'name': 'John',
///   'email': 'john@example.com',
/// });
/// 
/// // Read object
/// final user = await SecurityService().readObject('user');
