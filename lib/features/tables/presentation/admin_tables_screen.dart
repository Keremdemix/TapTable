import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../application/table_providers.dart';
import '../data/table_models.dart';
import '../../../core/network/api_exception.dart';

class AdminTablesScreen extends ConsumerWidget {
  const AdminTablesScreen({super.key});

  (String, Color) _statusInfo(TableStatus status) => switch (status) {
        TableStatus.available => ('Müsait', Colors.green),
        TableStatus.occupied => ('Dolu', Colors.orange),
        TableStatus.reserved => ('Rezerve', Colors.blue),
        TableStatus.outOfService => ('Kapalı', Colors.grey),
      };

  Future<void> _showTableForm(BuildContext context, WidgetRef ref, {TableResponseDto? existing}) async {
    final numberController = TextEditingController(text: existing?.tableNumber.toString() ?? '');
    final capacityController = TextEditingController(text: existing?.capacity.toString() ?? '4');
    bool isActive = existing?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(existing == null ? 'Yeni Masa' : 'Masa ${existing.tableNumber} Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberController,
                decoration: const InputDecoration(labelText: 'Masa Numarası'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(labelText: 'Kapasite'),
                keyboardType: TextInputType.number,
              ),
              if (existing != null) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  value: isActive,
                  onChanged: (val) => setState(() => isActive = val),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: () async {
                final number = int.tryParse(numberController.text);
                final capacity = int.tryParse(capacityController.text);
                if (number == null || capacity == null) return;

                try {
                  final repository = ref.read(tableRepositoryProvider);
                  if (existing == null) {
                    await repository.createTable(tableNumber: number, capacity: capacity);
                  } else {
                    await repository.updateTable(
                      id: existing.id,
                      tableNumber: number,
                      capacity: capacity,
                      isActive: isActive,
                    );
                  }
                  ref.invalidate(tablesProvider);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on ApiException catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, TableResponseDto table) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masayı Sil'),
        content: Text('Masa ${table.tableNumber} silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(tableRepositoryProvider).deleteTable(table.id);
      ref.invalidate(tablesProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showQrDialog(BuildContext context, WidgetRef ref, TableResponseDto table) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Masa ${table.tableNumber} — QR Kod'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: table.qrCodeUrl, size: 200),
            const SizedBox(height: 12),
            Text(table.qrCodeUrl, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Kapat')),
          FilledButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: dialogContext,
                builder: (confirmContext) => AlertDialog(
                  title: const Text('Yeni Oturum Oluşturulsun mu?'),
                  content: const Text(
                    'Bu işlem masadaki mevcut müşteri oturumunu geçersiz kılar. '
                    'Fiziksel QR kod değişmez, sadece eski oturum sonlanır.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(confirmContext, false), child: const Text('Vazgeç')),
                    FilledButton(onPressed: () => Navigator.pop(confirmContext, true), child: const Text('Devam Et')),
                  ],
                ),
              );
              if (confirmed != true) return;

              try {
                await ref.read(tableRepositoryProvider).regenerateQr(table.id);
                ref.invalidate(tablesProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on ApiException catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: const Text('Yeni Oturum Aç'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Masalar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTableForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(tablesProvider),
        child: tablesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Hata: $err')),
          data: (tables) {
            if (tables.isEmpty) return const Center(child: Text('Henüz masa eklenmedi.'));

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                final (label, color) = _statusInfo(table.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Text('${table.tableNumber}',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('Masa ${table.tableNumber}'),
                    subtitle: Text(
                        'Kapasite: ${table.capacity}  •  $label${table.isActive ? '' : '  •  Pasif'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.qr_code), onPressed: () => _showQrDialog(context, ref, table)),
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showTableForm(context, ref, existing: table)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(context, ref, table)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}