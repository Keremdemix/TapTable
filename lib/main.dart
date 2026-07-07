import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/entry/entry_screen.dart';

void main() {
  final uri = Uri.base;

  print('BASE: $uri');
  print('PATH: ${uri.path}');
  print('QUERY: ${uri.queryParameters}');

  final token = uri.queryParameters['token'] ?? uri.queryParameters['t'];

  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false, 
        home: (token != null && token.isNotEmpty)
            ? EntryScreen(token: token)
            : const Scaffold(
              
                body: Center(
                  child: Text('QR kod bekleniyor...'),
                ),
                
              ),
      ),
    ),
  );
}