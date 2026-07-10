import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import 'session_storage.dart';

class CustomerSession {
  final int tableId;
  final int tableNumber;
  final String restaurantName;
  final String? logoUrl;
  final String primaryColorHex;
  final String accentColorHex;
  final String sessionKey; // ← EKLENDİ

  CustomerSession({
    required this.tableId,
    required this.tableNumber,
    required this.restaurantName,
    required this.logoUrl,
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.sessionKey, // ← EKLENDİ
  });

  factory CustomerSession.fromJson(Map<String, dynamic> json) {
    return CustomerSession(
      tableId: json['tableId'] as int,
      tableNumber: json['tableNumber'] as int,
      restaurantName: json['restaurantName'] as String,
      logoUrl: json['logoUrl'] as String?,
      primaryColorHex: json['primaryColorHex'] as String,
      accentColorHex: json['accentColorHex'] as String,
      sessionKey: json['sessionKey'] as String, // ← EKLENDİ
    );
  }
}

final sessionStorageProvider = Provider((ref) => SessionStorage());
final apiClientProvider = Provider(
  (ref) => ApiClient(ref.read(sessionStorageProvider)),
);

/// URL'deki ?token= (veya ?t=) değeri — artık masaya sabit bağlı QrToken.
final qrTokenProvider = StateProvider<String?>((ref) => null);

final customerSessionProvider = FutureProvider.autoDispose<CustomerSession>((
  ref,
) async {
  final urlToken = ref.watch(qrTokenProvider);
  final storage = ref.read(sessionStorageProvider);
  final apiClient = ref.read(apiClientProvider);

  // QR'daki token sabit olduğu için URL'de her zaman mevcut olmalı.
  // Yine de daha önce saklanmış SessionKey'e düşme ihtimali için bırakıldı.
  final token = urlToken ?? await storage.getToken();

  if (token == null) {
    throw Exception('Geçersiz bağlantı — lütfen QR kodu tekrar okutun.');
  }

  final json = await apiClient.resolveSession(token);
  final session = CustomerSession.fromJson(json);

  // KRİTİK: URL'deki sabit QrToken değil, backend'in döndürdüğü GERÇEK
  // (ve rotate olabilen) SessionKey saklanır. Bundan sonraki tüm API
  // çağrıları (X-QR-Token header'ı) bu değeri kullanır.
  await storage.saveToken(session.sessionKey);

  return session;
});
