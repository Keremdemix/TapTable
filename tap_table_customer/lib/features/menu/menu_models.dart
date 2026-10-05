class PublicMenuResponse {
  final int restaurantId;
  final String restaurantName;
  final List<PublicCategory> categories;

  PublicMenuResponse({
    required this.restaurantId,
    required this.restaurantName,
    required this.categories,
  });

  factory PublicMenuResponse.fromJson(Map<String, dynamic> json) {
    return PublicMenuResponse(
      restaurantId: json['restaurantId'] as int,
      restaurantName: json['restaurantName'] as String,
      categories: (json['categories'] as List)
          .map((c) => PublicCategory.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PublicCategory {
  final int id;
  final String name;
  final List<PublicMenuItem> items;

  PublicCategory({required this.id, required this.name, required this.items});

  factory PublicCategory.fromJson(Map<String, dynamic> json) {
    return PublicCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      items: (json['items'] as List)
          .map((i) => PublicMenuItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PublicMenuItem {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;

  PublicMenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
  });

  factory PublicMenuItem.fromJson(Map<String, dynamic> json) {
    return PublicMenuItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
    );
  }
}