import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_staff/core/network/providers.dart';
import 'package:tap_table_staff/features/auth/application/jwt_claims.dart';

final currentUserClaimsProvider = FutureProvider<JwtClaims?>((ref) async {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final token = await tokenStorage.getAccessToken();
  if (token == null) return null;
  return JwtClaims.fromToken(token);
});

final currentRestaurantIdProvider = FutureProvider<int>((ref) async {
  final claims = await ref.watch(currentUserClaimsProvider.future);
  final idStr = claims?.restaurantId;
  if (idStr == null) {
    throw Exception('Restoran bilgisi bulunamadı — lütfen tekrar giriş yapın.');
  }
  return int.parse(idStr);
});