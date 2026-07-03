class RestaurantBrandingDto {
  final String? logoUrl;
  final String primaryColorHex;
  final String accentColorHex;

  RestaurantBrandingDto({
    this.logoUrl,
    required this.primaryColorHex,
    required this.accentColorHex,
  });

  factory RestaurantBrandingDto.fromJson(Map<String, dynamic> json) {
    return RestaurantBrandingDto(
      logoUrl: json['logoUrl'] as String?,
      primaryColorHex: json['primaryColorHex'] as String? ?? '#1A1A1A',
      accentColorHex: json['accentColorHex'] as String? ?? '#FF6B35',
    );
  }
}