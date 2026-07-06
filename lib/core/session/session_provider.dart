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

  CustomerSession({
    required this.tableId,
    required this.tableNumber,
    required this.restaurantName,
    required this.logoUrl,
    required this.primaryColorHex,
    required this.accentColorHex,
  });

  factory CustomerSession.fromJson(Map<String, dynamic> json) {
    return CustomerSession(
      tableId: json['tableId'] as int,
      tableNumber: json['tableNumber'] as int,
      restaurantName: json['restaurantName'] as String,
      logoUrl: json['logoUrl'] as String?,
      primaryColorHex: json['primaryColorHex'] as String,
      accentColorHex: json['accentColorHex'] as String,
    );
  }
}

final sessionStorageProvider = Provider((ref) => SessionStorage());
final apiClientProvider = Provider((ref) => ApiClient(ref.read(sessionStorageProvider)));

/// URL'deki ?token= (veya ?t=) değeri — uygulama açılışında EntryScreen tarafından set edilir.
final qrTokenProvider = StateProvider<String?>((ref) => null);

final customerSessionProvider =
    FutureProvider.autoDispose<CustomerSession>((ref) async {
  final urlToken = ref.watch(qrTokenProvider);
  final storage = ref.read(sessionStorageProvider);
  final apiClient = ref.read(apiClientProvider);

  // URL'de token varsa onu kullan; yoksa daha önce saklanmış token'a düş
  // (sayfa yenilenirse token URL'de kalmayabilir).
  final token = urlToken ?? await storage.getToken();

  if (token == null) {
    throw Exception('Geçersiz bağlantı — lütfen QR kodu tekrar okutun.');
  }

  final json = await apiClient.resolveSession(token);
  await storage.saveToken(token);

  return CustomerSession.fromJson(json);
});