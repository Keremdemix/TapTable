import '../../../core/network/api_client.dart';
import 'menu_models.dart';

class MenuRepository {
  final ApiClient _apiClient;
  MenuRepository(this._apiClient);

  // ── Kategoriler ──────────────────────────────────────────────────────
  Future<List<CategoryResponseDto>> getCategories() async {
    final list = await _apiClient.getList('/menu/categories');
    return list.map((j) => CategoryResponseDto.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<CategoryResponseDto> createCategory({required String name, required int sortOrder}) async {
    final json = await _apiClient.post('/menu/categories', data: {'name': name, 'sortOrder': sortOrder});
    return CategoryResponseDto.fromJson(json);
  }

  Future<CategoryResponseDto> updateCategory({
    required int id,
    required String name,
    required int sortOrder,
    required bool isActive,
  }) async {
    final json = await _apiClient.put('/menu/categories/$id', data: {
      'name': name,
      'sortOrder': sortOrder,
      'isActive': isActive,
    });
    return CategoryResponseDto.fromJson(json);
  }

  Future<void> deleteCategory(int id) => _apiClient.delete('/menu/categories/$id');

  // ── Ürünler ──────────────────────────────────────────────────────────
  Future<List<MenuItemResponseDto>> getItems({int? categoryId}) async {
    final query = categoryId != null ? {'categoryId': categoryId} : null;
    final list = await _apiClient.getList('/menu/items', query: query);
    return list.map((j) => MenuItemResponseDto.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<MenuItemResponseDto> createItem({
    required int categoryId,
    required String name,
    String? description,
    required double price,
    String? imageUrl,
    required int sortOrder,
  }) async {
    final json = await _apiClient.post('/menu/items', data: {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
    });
    return MenuItemResponseDto.fromJson(json);
  }

  Future<MenuItemResponseDto> updateItem({
    required int id,
    required int categoryId,
    required String name,
    String? description,
    required double price,
    String? imageUrl,
    required int sortOrder,
    required bool isAvailable,
    required bool isActive,
  }) async {
    final json = await _apiClient.put('/menu/items/$id', data: {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'isAvailable': isAvailable,
      'isActive': isActive,
    });
    return MenuItemResponseDto.fromJson(json);
  }

  Future<MenuItemResponseDto> setAvailability({required int id, required bool isAvailable}) async {
    final json = await _apiClient.patch('/menu/items/$id/availability', data: {'isAvailable': isAvailable});
    return MenuItemResponseDto.fromJson(json);
  }

  Future<void> deleteItem(int id) => _apiClient.delete('/menu/items/$id');
}