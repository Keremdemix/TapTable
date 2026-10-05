import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/providers.dart';
import '../data/table_repository.dart';
import '../data/table_models.dart';
import '../data/table_layout_models.dart';

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return TableRepository(ref.watch(apiClientProvider));
});

final tablesProvider = FutureProvider.autoDispose<List<TableResponseDto>>((ref) async {
  final repository = ref.watch(tableRepositoryProvider);
  final tables = await repository.getTables();
  tables.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
  return tables;
});

final tableLayoutProvider = FutureProvider.autoDispose<List<TableLayoutResponseDto>>((ref) async {
  return ref.watch(tableRepositoryProvider).getLayout();
});