import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_response.dart';
import '../application/jwt_claims.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepository(this._apiClient, this._tokenStorage);

  Future<JwtClaims> login({required String email, required String password}) async {
    final json = await _apiClient.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final auth = AuthResponse.fromJson(json);
    await _tokenStorage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );

    return JwtClaims.fromToken(auth.accessToken);
  }

  /// Uygulama açılışında — daha önce login olunmuş mu kontrol eder
  Future<JwtClaims?> restoreSession() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || JwtDecoder.isExpired(token)) return null;
    return JwtClaims.fromToken(token);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } on ApiException {
      // token zaten geçersizse backend hata dönebilir — yine de local temizliği yap
    } finally {
      await _tokenStorage.clear();
    }
  }
}