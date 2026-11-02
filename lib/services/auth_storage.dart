import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();
  
  static const String _keyToken = 'token';
  static const String _keyStudentId = 'student_id';

  // --- TOKEN ---
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // --- STUDENT ID ---
  static Future<void> saveStudentId(String studentId) async {
    await _storage.write(key: _keyStudentId, value: studentId);
  }

  static Future<String?> getStudentId() async {
    return await _storage.read(key: _keyStudentId);
  }

  static Future<void> deleteStudentId() async {
    await _storage.delete(key: _keyStudentId);
  }

  // --- FEATURES ---
  static Future<void> saveAllowedFeatures(List<String> features) async {
    // SharedPreferences is fine for non-sensitive data like feature flags
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('allowed_features', features);
  }

  static Future<List<String>> getAllowedFeatures() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('allowed_features') ?? [];
  }

  // --- CLEAR ALL ---
  static Future<void> clearAll() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('allowed_features');
  }
}
