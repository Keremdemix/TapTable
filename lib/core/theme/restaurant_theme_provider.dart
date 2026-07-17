import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helper/colorFromHex.dart';
import '../session/session_provider.dart';

class RestaurantThemeData {
  final Color primary;
  final Color accent;

  const RestaurantThemeData({required this.primary, required this.accent});
}

final restaurantThemeProvider = Provider<RestaurantThemeData>((ref) {
  final session = ref.watch(customerSessionProvider).value;

  return RestaurantThemeData(
    primary: safeColorFromHex(session?.primaryColorHex, Colors.teal),
    accent: safeColorFromHex(session?.accentColorHex, Colors.deepOrange),
  );
});
