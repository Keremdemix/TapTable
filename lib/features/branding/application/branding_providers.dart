import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_staff/features/auth/application/current_user_providers.dart';
import '../../../core/network/providers.dart';
import '../data/branding_models.dart';
import '../data/branding_repository.dart';

final brandingRepositoryProvider = Provider<BrandingRepository>((ref) {
  return BrandingRepository(ref.watch(apiClientProvider));
});

final brandingProvider =
    FutureProvider.autoDispose<RestaurantBrandingDto>((ref) async {
  final restaurantId = await ref.watch(currentRestaurantIdProvider.future);
  final repository = ref.watch(brandingRepositoryProvider);
  return repository.getBranding(restaurantId);
});