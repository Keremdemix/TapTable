import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_provider.dart';
import '../menu/menu_screen.dart';

class EntryScreen extends ConsumerStatefulWidget {
  final String token;
  const EntryScreen({super.key, required this.token});

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(qrTokenProvider.notifier).state = widget.token;
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
        data: (session) => MenuScreen(session: session),
      ),
    );
  }
}
