import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import 'session_storage.dart';

class CustomerSession {
  final int tableId;
  final String sessionKey;
  final String restaurantName;
  final String? logoUrl;
  final String primaryColorHex;
  final String accentColorHex;

  CustomerSession({
    required this.tableId,
    required this.sessionKey,
    required this.restaurantName,
    required this.logoUrl,
    required this.primaryColorHex,
    required this.accentColorHex,
  });

  factory CustomerSession.fromQrResponse(Map<String, dynamic> json) {
    final restaurant = json['restaurant'] as Map<String, dynamic>;
    return CustomerSession(
      tableId: json['tableId'] as int,
      sessionKey: json['sessionKey'] as String,
      restaurantName: restaurant['name'] as String,
      logoUrl: restaurant['logoUrl'] as String?,
      primaryColorHex: restaurant['primaryColorHex'] as String,
      accentColorHex: restaurant['accentColorHex'] as String,
    );
  }
}

final sessionStorageProvider = Provider((ref) => SessionStorage());

final apiClientProvider = Provider((ref) => ApiClient(ref.read(sessionStorageProvider)));

/// tableId, uygulama açılışında URL query'sinden okunup buraya set edilir.
final tableIdProvider = StateProvider<int?>((ref) => null);

final customerSessionProvider =
    FutureProvider.autoDispose<CustomerSession>((ref) async {
  final tableId = ref.watch(tableIdProvider);
  if (tableId == null) {
    throw Exception('Masa bulunamadı — QR kodu geçersiz.');
  }

  final apiClient = ref.read(apiClientProvider);
  final storage = ref.read(sessionStorageProvider);

  Map<String, dynamic> json;
  try {
    // Önce aktif session var mı diye bak
    json = await apiClient.get('/qr/active/$tableId');
  } catch (_) {
    // Yoksa yeni session oluştur
    json = await apiClient.post('/qr/create', data: {'tableId': tableId});
  }

  final session = CustomerSession.fromQrResponse(json);
  await storage.saveSession(sessionKey: session.sessionKey, tableId: tableId);
  return session;
});