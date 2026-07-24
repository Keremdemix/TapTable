import 'package:flutter/material.dart';

/// Tüm ekranlarda restoranın `primary` rengini kullanan ortak AppBar.
///
/// Kullanım:
/// ```dart
/// appBar: ThemedAppBar(
///   title: 'Sepet & Siparişlerim',
///   primary: primary,
///   actions: [...], // opsiyonel
/// ),
/// ```
class ThemedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color primary;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const ThemedAppBar({
    super.key,
    required this.title,
    required this.primary,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: primary,
      foregroundColor: Colors.white,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
