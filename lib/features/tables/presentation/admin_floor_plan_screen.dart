import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/table_providers.dart';
import '../data/table_layout_models.dart';
import 'table_shape_widget.dart';
import 'package:tap_table_staff/core/constants/layout_constants.dart';

const double _canvasWidth = LayoutConstants.canvasWidth;
const double _canvasHeight = LayoutConstants.canvasHeight;
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

  // Transform controller — zoom/pan için
  final TransformationController _transformController =
      TransformationController();

  // Aktif drag bilgisi
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

  TableLayoutResponseDto? get _selectedTable =>
      _layouts?.firstWhere((t) => t.tableId == _selectedTableId,
          orElse: () => throw StateError('not found'));

  // ─── Pozisyon güncelleme ─────────────────────────────────────────────────────

  /// Anlık sürükleme sırasında sadece ilgili masayı günceller (setState yok).
  void _applyDragOffset(int tableId, Offset delta) {
    if (_layouts == null || _drag == null) return;
    final idx = _layouts!.indexWhere((t) => t.tableId == tableId);
    if (idx == -1) return;

    final t = _layouts![idx];
    final scale = _currentScale;
    final rawX = _drag!.startPosition.dx + delta.dx / scale;
    final rawY = _drag!.startPosition.dy + delta.dy / scale;

    final newX = _snapValue(rawX, _canvasWidth - t.width);
    final newY = _snapValue(rawY, _canvasHeight - t.height);

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

  // ─── Kaydet ─────────────────────────────────────────────────────────────────

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

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(tableLayoutProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
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
                    Expanded(child: _buildCanvas()),
                    if (_selectedTableId != null) _buildSidebar(),
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
        // Zoom sıfırla
        IconButton(
          tooltip: 'Görünümü sıfırla',
          icon: const Icon(Icons.center_focus_strong_outlined, size: 20),
          onPressed: () => _transformController.value = Matrix4.identity(),
        ),
        // Kaydet butonu
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
      // panEnabled=false: pan olayları masaya değil InteractiveViewer'a gitmesin
      // Masa sürüklenirken zoom/pan devre dışı olacak şekilde _drag ile yönetiyoruz.
      // panEnabled: _drag == null,
      minScale: 0.3,
      maxScale: 3.0,
      constrained: false,
      child: _buildCanvasContent(),
    );
  }

  Widget _buildCanvasContent() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Canvas boş alanına tıklanınca seçimi kaldır
      onTap: () => setState(() => _selectedTableId = null),
      child: Container(
        width: _canvasWidth,
        height: _canvasHeight,
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
        // Çift tıklama → şekil değiştir
        onDoubleTap: () => _toggleShape(t.tableId),

        // Tek tıklama → seç
        onTap: () {
          setState(() {
            _selectedTableId = (_selectedTableId == t.tableId) ? null : t.tableId;
          });
        },

        // Sürükleme başlangıcı
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

        // Sürükleme devam
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

        // Sürükleme bitti
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

  // ─── Sağ panel (seçili masa bilgisi) ─────────────────────────────────────────

  Widget _buildSidebar() {
    final t = _layouts?.where((x) => x.tableId == _selectedTableId).firstOrNull;
    if (t == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
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
                  onPressed: () =>
                      setState(() => _selectedTableId = null),
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
                    label: 'Konum',
                    value: '${t.positionX}, ${t.positionY}'),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // Şekil değiştir butonu
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
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
          ),
        ],
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