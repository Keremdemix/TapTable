import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_table_customer/theme/restaurant_theme.dart';
import '../../core/session/session_provider.dart';
import '../menu/menu_screen.dart';

class EntryScreen extends ConsumerStatefulWidget {
  final int tableId;
  const EntryScreen({super.key, required this.tableId});

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tableIdProvider.notifier).state = widget.tableId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(customerSessionProvider);

    return Scaffold(
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Bir şeyler ters gitti: $err',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // entry_screen.dart içindeki build metodunu güncelle
        data: (session) {
          print('primaryColorHex = "${session.primaryColorHex}"');
          print('accentColorHex = "${session.accentColorHex}"');

          return Theme(
            data: buildRestaurantTheme(
              primaryColorHex: session.primaryColorHex,
              accentColorHex: session.accentColorHex,
            ),
            child: MenuScreen(session: session),
          );
        }
      ),
    );
  }
}