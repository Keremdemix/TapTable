import 'package:jwt_decoder/jwt_decoder.dart';

class JwtClaims {
  final String? userId;
  final String? role;
  final String? restaurantId;

  const JwtClaims({this.userId, this.role, this.restaurantId});

  factory JwtClaims.fromToken(String token) {
    final decoded = JwtDecoder.decode(token);

    return JwtClaims(
      userId: _readClaim(decoded, [
        'nameid',
        'sub',
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      ]),
      role: _readClaim(decoded, [
        'role',
        'http://schemas.microsoft.com/ws/2008/06/identity/claims/role',
      ]),
      restaurantId: _readClaim(decoded, ['restaurantId']),
    );
  }

  static String? _readClaim(Map<String, dynamic> decoded, List<String> keys) {
    for (final key in keys) {
      if (decoded.containsKey(key)) return decoded[key]?.toString();
    }
    return null;
  }
}