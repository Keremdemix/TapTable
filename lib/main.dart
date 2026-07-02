import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/entry/entry_screen.dart';

void main() {
  final uri = Uri.base;

  print('BASE: $uri');
  print('PATH: ${uri.path}');
  print('QUERY: ${uri.queryParameters}');

  final tableId = int.tryParse(uri.queryParameters['table'] ?? '');

  runApp(
    ProviderScope(
      child: MaterialApp(
        home: tableId != null
            ? EntryScreen(tableId: tableId)
            : const Scaffold(
                body: Center(
                  child: Text('QR kod bekleniyor...'),
                ),
              ),
      ),
    ),
  );
}