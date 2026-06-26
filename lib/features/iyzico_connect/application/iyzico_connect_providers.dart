import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/providers.dart';
import '../data/iyzico_connect_models.dart';
import '../data/iyzico_connect_repository.dart';

final iyzicoConnectRepositoryProvider = Provider<IyzicoConnectRepository>((ref) {
  return IyzicoConnectRepository(ref.watch(apiClientProvider));
});

final iyzicoSubMerchantStatusProvider =
    FutureProvider.autoDispose<IyzicoSubMerchantStatusDto>((ref) async {
  return ref.watch(iyzicoConnectRepositoryProvider).getStatus();
});