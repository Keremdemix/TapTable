import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_provider.dart';
import 'menu_models.dart';

final publicMenuProvider =
    FutureProvider.autoDispose<PublicMenuResponse>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final json = await apiClient.get('/public/menu');
  return PublicMenuResponse.fromJson(json);
});