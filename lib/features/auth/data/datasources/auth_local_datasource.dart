import 'package:mgt_app/shared/services/storage_service.dart';

class AuthLocalDataSource {
  static const _kAuthTokenKey = 'auth_token';
  String? _token;

  Future<void> saveToken(String token) async {
    _token = token;
    try {
      await StorageService.setString(_kAuthTokenKey, token); // use static API
    } catch (_) {
      // ignore storage errors; in-memory fallback remains
    }
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    try {
      _token = StorageService.getString(_kAuthTokenKey); // sync getter
      return _token;
    } catch (_) {
      return _token; // may be null
    }
  }

  Future<void> clearToken() async {
    _token = null;
    try {
      await StorageService.remove(_kAuthTokenKey); // use static API
    } catch (_) {
      // ignore
    }
  }
}