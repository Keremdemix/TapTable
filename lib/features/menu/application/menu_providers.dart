import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/providers.dart';
import '../data/menu_models.dart';
import '../data/menu_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.watch(apiClientProvider));
});

final categoriesProvider = FutureProvider.autoDispose<List<CategoryResponseDto>>((ref) async {
  final repository = ref.watch(menuRepositoryProvider);
  final categories = await repository.getCategories();
  categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return categories;
});

final menuItemsProvider = FutureProvider.autoDispose<List<MenuItemResponseDto>>((ref) async {
  final repository = ref.watch(menuRepositoryProvider);
  final items = await repository.getItems();
  items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return items;
});