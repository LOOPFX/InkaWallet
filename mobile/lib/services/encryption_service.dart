import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

/// EncryptionService provides encryption and hashing functionality
/// Uses AES-256 for data encryption and SHA-256 for password hashing
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // Use a secure key in production (store in secure storage)
  // This is a placeholder - should be generated and stored securely
  final _key = encrypt.Key.fromLength(32);
  final _iv = encrypt.IV.fromLength(16);

  /// Encrypt sensitive data using AES-256
  String encryptData(String plainText) {
    try {
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_key, mode: encrypt.AESMode.cbc),
      );
      
      final encrypted = encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      rethrow;
    }
  }

  /// Decrypt data
  String decryptData(String encryptedText) {
    try {
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_key, mode: encrypt.AESMode.cbc),
      );
      
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      print('Decryption error: $e');
      rethrow;
    }
  }

  /// Hash password using SHA-256 (in production, use bcrypt on backend)
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate secure random string
  String generateSecureToken(int length) {
    final random = encrypt.SecureRandom(length);
    return base64Url.encode(random.bytes);
  }

  /// Encrypt transaction data
  Map<String, dynamic> encryptTransaction(Map<String, dynamic> transaction) {
    final encryptedData = <String, dynamic>{};
    
    // Encrypt sensitive fields
    final sensitiveFields = ['amount', 'recipient_phone', 'description'];
    
    for (var entry in transaction.entries) {
      if (sensitiveFields.contains(entry.key)) {
        encryptedData[entry.key] = encryptData(entry.value.toString());
      } else {
        encryptedData[entry.key] = entry.value;
      }
    }
    
    return encryptedData;
  }

  /// Decrypt transaction data
  Map<String, dynamic> decryptTransaction(Map<String, dynamic> encryptedTransaction) {
    final decryptedData = <String, dynamic>{};
    
    final sensitiveFields = ['amount', 'recipient_phone', 'description'];
    
    for (var entry in encryptedTransaction.entries) {
      if (sensitiveFields.contains(entry.key)) {
        decryptedData[entry.key] = decryptData(entry.value.toString());
      } else {
        decryptedData[entry.key] = entry.value;
      }
    }
    
    return decryptedData;
  }

  /// Validate data integrity using checksum
  String generateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify checksum
  bool verifyChecksum(String data, String checksum) {
    return generateChecksum(data) == checksum;
  }
}
