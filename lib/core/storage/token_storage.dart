import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:html' as html;

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final _storage = const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      html.window.localStorage[_accessTokenKey] = accessToken;
      html.window.localStorage[_refreshTokenKey] = refreshToken;
      return;
    }

    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      return html.window.localStorage[_accessTokenKey];
    }

    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      return html.window.localStorage[_refreshTokenKey];
    }

    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_accessTokenKey);
      html.window.localStorage.remove(_refreshTokenKey);
      return;
    }

    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
