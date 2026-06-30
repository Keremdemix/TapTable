import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../application/table_providers.dart';
import '../data/table_layout_models.dart';
import '../data/table_models.dart';
import '../../../core/network/api_exception.dart';
import 'table_shape_widget.dart';
import 'package:tap_table_staff/core/constants/layout_constants.dart';

const double _gridSnap = 40;
const double _dragThreshold = 4.0;

/// Aktif olarak sürüklenen masanın durumunu tutar.
class _DragState {
  final int tableId;
  final Offset startPointer;
  final Offset startPosition;
  bool moved;

  _DragState({
    required this.tableId,
    required this.startPointer,
    required this.startPosition,
    this.moved = false,
  });
}

class AdminFloorPlanScreen extends ConsumerStatefulWidget {
  const AdminFloorPlanScreen({super.key});

  @override
  ConsumerState<AdminFloorPlanScreen> createState() =>
      _AdminFloorPlanScreenState();
}

class _AdminFloorPlanScreenState extends ConsumerState<AdminFloorPlanScreen> {
  List<TableLayoutResponseDto>? _layouts;
  bool _saving = false;
  bool _dirty = false;
  int? _selectedTableId;

  final TransformationController _transformController =
      TransformationController();

  _DragState? _drag;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  // ─── Veri ───────────────────────────────────────────────────────────────────

  void _initFrom(List<TableLayoutResponseDto> data) {
    _layouts ??= List.of(data);
  }

  /// Liste/CRUD verisi değiştiğinde (masa eklendi/silindi) cache'i sıfırlayıp
  /// her iki provider'ı da tazeler.
  void _refreshAfterMutation() {
    ref.invalidate(tablesProvider);
    ref.invalidate(tableLayoutProvider);
    setState(() {
      _layouts = null;
      _selectedTableId = null;
    });
  }

  (String, Color) _statusInfo(TableStatus status) => switch (status) {
        TableStatus.available => ('Müsait', Colors.green),
        TableStatus.occupied => ('Dolu', Colors.orange),
        TableStatus.reserved => ('Rezerve', Colors.blue),
        TableStatus.outOfService => ('Kapalı', Colors.grey),
      };

  // ─── Pozisyon güncelleme ─────────────────────────────────────────────────────

  void _applyDragOffset(int tableId, Offset delta) {
    if (_layouts == null || _drag == null) return;
    final idx = _layouts!.indexWhere((t) => t.tableId == tableId);
    if (idx == -1) return;

    final t = _layouts![idx];
    final scale = _currentScale;
    final rawX = _drag!.startPosition.dx + delta.dx / scale;
    final rawY = _drag!.startPosition.dy + delta.dy / scale;

    final newX = _snapValue(rawX, LayoutConstants.canvasWidth - t.width);
    final newY = _snapValue(rawY, LayoutConstants.canvasHeight - t.height);

    _layouts![idx] = t.copyWith(positionX: newX, positionY: newY);
  }

  void _commitDrag() {
    setState(() => _dirty = true);
  }

  int _snapValue(double v, double max) =>
      ((v / _gridSnap).round() * _gridSnap).clamp(0, max).toInt();

  double get _currentScale {
    final m = _transformController.value;
    return m.getMaxScaleOnAxis();
  }

  // ─── Şekil değiştirme (çift tıklama) ────────────────────────────────────────

  void _toggleShape(int tableId) {
    setState(() {
      _layouts = _layouts!.map((t) {
        if (t.tableId != tableId) return t;
        return t.copyWith(
            shape: t.shape == 'circle' ? 'rectangle' : 'circle');
      }).toList();
      _dirty = true;
    });
  }

  // ─── Kaydet (kat planı pozisyonları) ─────────────────────────────────────────

  Future<void> _save() async {
    if (_layouts == null) return;
    setState(() => _saving = true);
    try {
      final items = _layouts!
          .map((t) => UpdateTableLayoutItemInput(
                tableId: t.tableId,
                positionX: t.positionX,
                positionY: t.positionY,
                width: t.width,
                height: t.height,
                shape: t.shape,
              ))
          .toList();
      await ref.read(tableRepositoryProvider).saveLayout(items);
      if (mounted) {
        setState(() => _dirty = false);
        _showSnack('Düzen kaydedildi.', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack('Kaydedilemedi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ─── CRUD: Masa ekle / düzenle ───────────────────────────────────────────────

  Future<void> _showTableForm({TableResponseDto? existing}) async {
    final numberController =
        TextEditingController(text: existing?.tableNumber.toString() ?? '');
    final capacityController =
        TextEditingController(text: existing?.capacity.toString() ?? '4');
    bool isActive = existing?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
              existing == null ? 'Yeni Masa' : 'Masa ${existing.tableNumber} Düzenle'),
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
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Vazgeç')),
            FilledButton(
              onPressed: () async {
                final number = int.tryParse(numberController.text);
                final capacity = int.tryParse(capacityController.text);
                if (number == null || capacity == null) return;

                try {
                  final repository = ref.read(tableRepositoryProvider);
                  if (existing == null) {
                    await repository.createTable(
                        tableNumber: number, capacity: capacity);
                  } else {
                    await repository.updateTable(
                      id: existing.id,
                      tableNumber: number,
                      capacity: capacity,
                      isActive: isActive,
                    );
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  _refreshAfterMutation();
                } on ApiException catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext)
                        .showSnackBar(SnackBar(content: Text(e.message)));
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

  // ─── CRUD: Masa sil ───────────────────────────────────────────────────────────

  Future<void> _confirmDelete(TableResponseDto table) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Masayı Sil'),
        content: Text('Masa ${table.tableNumber} silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(tableRepositoryProvider).deleteTable(table.id);
      _refreshAfterMutation();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  // ─── QR göster / yeni oturum aç ──────────────────────────────────────────────

  Future<void> _showQrDialog(TableResponseDto table) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Masa ${table.tableNumber} — QR Kod'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(data: table.qrCodeUrl, size: 200),
            ),
            const SizedBox(height: 12),
            Text(table.qrCodeUrl,
                style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Kapat')),
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
                    TextButton(
                        onPressed: () => Navigator.pop(confirmContext, false),
                        child: const Text('Vazgeç')),
                    FilledButton(
                        onPressed: () => Navigator.pop(confirmContext, true),
                        child: const Text('Devam Et')),
                  ],
                ),
              );
              if (confirmed != true) return;

              try {
                await ref.read(tableRepositoryProvider).regenerateQr(table.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _refreshAfterMutation();
              } on ApiException catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: const Text('Yeni Oturum Aç'),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(tableLayoutProvider);
    final tablesAsync = ref.watch(tablesProvider);

    return Scaffold(
      // Sidebar/özet panel de beyaz; canvas'ın bittiği yerde renk farkı
      // oluşmasın diye Scaffold arka planını da aynı renge çekiyoruz.
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Yeni Masa',
        onPressed: () => _showTableForm(),
        child: const Icon(Icons.add),
      ),
      body: layoutAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Hata: $err')),
        data: (data) {
          _initFrom(data);
          return Column(
            children: [
              _buildHintBar(),
              Expanded(
                child: Row(
                  children: [
                    // Canvas Expanded ile kalan tüm genişliği alır; sidebar/özet
                    // panel sabit genişlikte olduğundan toplamda her zaman doğru
                    // oranlanır — ayrı yüzde hesabına gerek yoktur.
                    Expanded(child: _buildCanvas()),
                    _selectedTableId != null
                        ? _buildSidebar(tablesAsync.valueOrNull)
                        : _buildSummaryPanel(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      title: Row(
        children: [
          const Text('Masa Düzeni',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          if (_dirty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '● Kaydedilmedi',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Görünümü sıfırla',
          icon: const Icon(Icons.center_focus_strong_outlined, size: 20),
          onPressed: () => _transformController.value = Matrix4.identity(),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: FilledButton.icon(
            onPressed: (_dirty && !_saving) ? _save : null,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 16),
            label: const Text('Kaydet', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  // ─── İpucu çubuğu ────────────────────────────────────────────────────────────

  Widget _buildHintBar() {
    return Container(
      width: double.infinity,
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Wrap(
        spacing: 24,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: const [
          _HintChip(icon: Icons.open_with, label: 'Sürükle → taşı'),
          _HintChip(icon: Icons.touch_app_outlined, label: 'Çift tıkla → şekil değiştir'),
          _HintChip(icon: Icons.info_outline, label: 'Tek tıkla → seç'),
          _HintChip(icon: Icons.pinch_outlined, label: 'Pinch → yakınlaştır'),
        ],
      ),
    );
  }

  // ─── Canvas ──────────────────────────────────────────────────────────────────

  Widget _buildCanvas() {
    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.3,
      maxScale: 3.0,
      constrained: false,
      alignment: Alignment.topLeft,
      boundaryMargin: EdgeInsets.zero,
      child: _buildCanvasContent(
        LayoutConstants.canvasWidth,
        LayoutConstants.canvasHeight,
      ),
    );
  }

  Widget _buildCanvasContent(double width, double height) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => setState(() => _selectedTableId = null),
      child: Container(
        alignment: Alignment.topLeft,
        width: LayoutConstants.canvasWidth,
        height: LayoutConstants.canvasHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: CustomPaint(
          painter: _GridPainter(),
          child: Stack(
            children: [
              if (_layouts != null)
                ..._layouts!.map((t) => _buildTableWidget(t)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Masa Widget ──────────────────────────────────────────────────────────────

  Widget _buildTableWidget(TableLayoutResponseDto t) {
    final isSelected = _selectedTableId == t.tableId;
    final isDraggingThis = _drag?.tableId == t.tableId;

    return Positioned(
      left: t.positionX.toDouble(),
      top: t.positionY.toDouble(),
      child: GestureDetector(
        onDoubleTap: () => _toggleShape(t.tableId),
        onTap: () {
          setState(() {
            _selectedTableId = (_selectedTableId == t.tableId) ? null : t.tableId;
          });
        },
        onPanStart: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(details.globalPosition);

          setState(() {
            _drag = _DragState(
              tableId: t.tableId,
              startPointer: local,
              startPosition: Offset(
                t.positionX.toDouble(),
                t.positionY.toDouble(),
              ),
            );
          });
        },
        onPanUpdate: (details) {
          if (_drag == null || _drag!.tableId != t.tableId) return;
          final RenderBox box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(details.globalPosition);

          final delta = local - _drag!.startPointer;
          if (!_drag!.moved && delta.distance > _dragThreshold) {
            _drag!.moved = true;
          }
          if (_drag!.moved) {
            setState(() => _applyDragOffset(t.tableId, delta));
          }
        },
        onPanEnd: (_) {
          if (_drag == null) return;
          final wasMoved = _drag!.moved;
          setState(() => _drag = null);
          if (wasMoved) _commitDrag();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: t.width.toDouble(),
          height: t.height.toDouble(),
          decoration: BoxDecoration(
            boxShadow: isDraggingThis
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]
                : isSelected
                    ? [
                        BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1)
                      ]
                    : [],
          ),
          child: TableShapeWidget(
            tableNumber: t.tableNumber,
            capacity: t.capacity,
            status: t.status,
            width: t.width.toDouble(),
            height: t.height.toDouble(),
            shape: t.shape,
            isSelected: isSelected,
          ),
        ),
      ),
    );
  }

  // ─── Sağ panel (varsayılan: özet istatistik) ─────────────────────────────────

  Widget _buildSummaryPanel() {
    final layouts = _layouts ?? const [];
    final total = layouts.length;
    final counts = <TableStatus, int>{};
    for (final t in layouts) {
      counts[t.status] = (counts[t.status] ?? 0) + 1;
    }

    Widget statRow(String label, int count, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ),
            Text('$count',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    // Sidebar (_buildSidebar) ile aynı sabit genişlik — canvas zaten Expanded
    // olduğu için bu, görsel olarak "kalan alanın küçük bir dilimi" gibi durur.
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('Özet',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statRow('Toplam Masa', total, Colors.grey.shade700),
                const Divider(height: 20),
                statRow('Müsait', counts[TableStatus.available] ?? 0, Colors.green),
                statRow('Dolu', counts[TableStatus.occupied] ?? 0, Colors.orange),
                statRow('Rezerve', counts[TableStatus.reserved] ?? 0, Colors.blue),
                statRow('Kapalı', counts[TableStatus.outOfService] ?? 0, Colors.grey),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Detayları görmek için bir masaya tıklayın.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sağ panel (seçili masa: bilgi + CRUD + QR) ──────────────────────────────

  Widget _buildSidebar(List<TableResponseDto>? allTables) {
    final t = _layouts?.where((x) => x.tableId == _selectedTableId).firstOrNull;
    if (t == null) return const SizedBox.shrink();

    // Layout DTO'su isActive/qrCodeUrl içermediği için eşleşen tam masa kaydını buluyoruz.
    final fullTable =
        allTables?.where((x) => x.id == t.tableId).firstOrNull;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Masa Bilgisi',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _selectedTableId = null),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // Bilgi satırları
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Masa No', value: '#${t.tableNumber}'),
                  _InfoRow(label: 'Kapasite', value: '${t.capacity} kişi'),
                  _InfoRow(
                      label: 'Durum',
                      value: _statusLabel(t.status.name),
                      valueColor: _statusColor(t.status.name)),
                  _InfoRow(
                      label: 'Şekil',
                      value: t.shape == 'circle' ? 'Yuvarlak' : 'Dikdörtgen'),
                  _InfoRow(
                      label: 'Konum', value: '${t.positionX}, ${t.positionY}'),
                  if (fullTable != null)
                    _InfoRow(
                        label: 'Aktif',
                        value: fullTable.isActive ? 'Evet' : 'Hayır'),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // Eylemler
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleShape(t.tableId),
                      icon: Icon(
                        t.shape == 'circle'
                            ? Icons.crop_square_outlined
                            : Icons.circle_outlined,
                        size: 16,
                      ),
                      label: Text(
                        t.shape == 'circle' ? 'Dikdörtgen yap' : 'Yuvarlak yap',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  if (fullTable != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showTableForm(existing: fullTable),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Düzenle',
                            style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showQrDialog(fullTable),
                        icon: const Icon(Icons.qr_code, size: 16),
                        label: const Text('QR Göster',
                            style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(fullTable),
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Colors.red),
                        label: const Text('Sil',
                            style: TextStyle(fontSize: 13, color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Masa detayları yükleniyor…',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Yardımcı ─────────────────────────────────────────────────────────────────

  String _statusLabel(String s) {
    switch (s) {
      case 'Available': return 'Boş';
      case 'Occupied':  return 'Dolu';
      case 'Reserved':  return 'Rezerve';
      default:          return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Available': return Colors.green.shade700;
      case 'Occupied':  return Colors.red.shade700;
      case 'Reserved':  return Colors.orange.shade700;
      default:          return Colors.grey;
    }
  }
}

// ─── Grid Painter ─────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += _gridSnap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += _gridSnap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Küçük yardımcı widget'lar ───────────────────────────────────────────────

class _HintChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HintChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.blue.shade700),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.blue.shade800)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }
}