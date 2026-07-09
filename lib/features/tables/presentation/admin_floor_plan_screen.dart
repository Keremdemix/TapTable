import 'dart:math' as math;

import 'package:flutter/gestures.dart';
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

/// Sidebar'ı gösterecek kadar geniş ekranlar için eşik. Altında masa
/// detayı ayrı bir sayfada (tam ekran) açılır — waiter_home_screen.dart
/// ile aynı mantık.
const double _sidebarBreakpoint = 700;

/// Aktif olarak sürüklenen masanın durumunu tutar.
class _DragState {
  final int tableId;
  final Offset startPointer;
  final Offset startPosition;
  bool moved = false;

  _DragState({
    required this.tableId,
    required this.startPointer,
    required this.startPosition,
  });
}

class AdminFloorPlanScreen extends ConsumerStatefulWidget {
  const AdminFloorPlanScreen({super.key});

  @override
  ConsumerState<AdminFloorPlanScreen> createState() =>
      _AdminFloorPlanScreenState();
}

class _AdminFloorPlanScreenState extends ConsumerState<AdminFloorPlanScreen>
    with SingleTickerProviderStateMixin {
  List<TableLayoutResponseDto>? _layouts;
  bool _saving = false;
  bool _dirty = false;
  int? _selectedTableId;

  /// Masa oluşturma/düzenleme formunda girilen boyut, veriler backend'den
  /// yeniden yüklendiğinde _initFrom içinde ilgili layout kaydına
  /// uygulanmak üzere burada bekletilir (tableNumber ile eşleştirilir,
  /// çünkü yeni masalarda henüz tableId bilinmiyor).
  ({int tableNumber, double width, double height})? _pendingSizeOverride;

  final TransformationController _transformController =
      TransformationController();

  late final AnimationController _animController;
  late final CurvedAnimation _curvedAnim;
  Matrix4Tween? _tween;

  _DragState? _drag;

  // Son fit edilen viewport boyutu ve o anki "ekrana sığdır" ölçeği.
  Size? _viewport;
  double _fitScale = 1.0;

  static const double _absoluteMinScale = 0.05;
  static const double _maxScale = 3.0;

  // Kaydırma sadece kullanıcı fit ölçeğinin üzerine yakınlaştığında anlamlı;
  // bu yüzden minScale her zaman güncel fit ölçeğine eşitlenir. Böylece
  // kullanıcı fit'in altına asla inemez ve fit halindeyken canvas her zaman
  // tam ortalanmış kalır.
  double _minScale = 1.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _curvedAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.addListener(() {
      final tween = _tween;
      if (tween != null) {
        _transformController.value = tween.evaluate(_curvedAnim);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  // ─── Veri ───────────────────────────────────────────────────────────────────

  /// Sunucudan gelen her yeni veriyi yerel canvas state'iyle birleştirir.
  /// Önceden bu metot sadece İLK yüklemede çalışıp sonra donuyordu
  /// (`_layouts ??=`); bu yüzden ne sunucudaki canlı değişiklikler
  /// (ör. ödeme sonrası masa boşa düşmesi) ne de art arda yapılan
  /// düzenlemeler doğru yansıyordu. Artık her veri geldiğinde çalışır:
  /// - Kaydedilmemiş (henüz "Kaydet"e basılmamış) konum/boyut/şekil
  ///   değişiklikleri korunur.
  /// - Durum/kapasite/masa numarası gibi sunucu kaynaklı alanlar her
  ///   zaman güncellenir.
  /// - Yeni eklenen masalar otomatik görünür, silinenler otomatik kaybolur.
  void _initFrom(List<TableLayoutResponseDto> data) {
    final current = _layouts;

    if (current == null) {
      _layouts = List.of(data);
    } else {
      final merged = <TableLayoutResponseDto>[];
      for (final fresh in data) {
        final localIdx = current.indexWhere((t) => t.tableId == fresh.tableId);
        if (localIdx == -1) {
          // Sunucuda yeni: yerelde henüz yok, olduğu gibi ekle.
          merged.add(fresh);
        } else {
          // Zaten yerelde var: kaydedilmemiş canvas alanlarını koru,
          // gerisini sunucudan güncelle.
          final local = current[localIdx];
          merged.add(
            fresh.copyWith(
              positionX: local.positionX,
              positionY: local.positionY,
              width: local.width,
              height: local.height,
              shape: local.shape,
            ),
          );
        }
      }
      _layouts = merged;
    }

    final pending = _pendingSizeOverride;
    if (pending != null) {
      final idx = _layouts!.indexWhere(
        (t) => t.tableNumber == pending.tableNumber,
      );
      if (idx != -1) {
        final t = _layouts![idx];
        _layouts![idx] = t.copyWith(
          width: pending.width.toInt(),
          height: pending.height.toInt(),
        );
        _pendingSizeOverride = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _dirty = true);
        });
      }
      // Eşleşme bulunamadıysa (masa henüz sunucu tarafında layout'a
      // yansımamış olabilir) pending override saklanmaya devam eder ve
      // bir sonraki veri gelişinde tekrar denenir.
    }
  }

  /// Liste/CRUD verisi değiştiğinde (masa eklendi/silindi/düzenlendi) her
  /// iki provider'ı da tazeler. `_layouts` artık burada sıfırlanmıyor —
  /// sunucudan gelen taze veri `_initFrom` içinde yerel (kaydedilmemiş)
  /// canvas değişiklikleriyle birleştiriliyor. Böylece bir masayı
  /// düzenlerken başka bir masadaki kaydedilmemiş konum/boyut/şekil
  /// değişikliği kaybolmuyor.
  void _refreshAfterMutation() {
    ref.invalidate(tablesProvider);
    ref.invalidate(tableLayoutProvider);
    setState(() => _selectedTableId = null);
  }

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

  // ─── Zoom / Pan / Fit ─────────────────────────────────────────────────────

  /// Verilen viewport için canvas'ı ortalayan "ekrana sığdır" matrisini üretir.
  Matrix4 _computeFitMatrix(Size viewport) {
    final canvasWidth = LayoutConstants.canvasWidth;
    final canvasHeight = LayoutConstants.canvasHeight;

    final sx = viewport.width / canvasWidth;
    final sy = viewport.height / canvasHeight;
    final scale = math.min(sx, sy).clamp(_absoluteMinScale, _maxScale);

    final dx = (viewport.width - canvasWidth * scale) / 2;
    final dy = (viewport.height - canvasHeight * scale) / 2;

    return Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  /// Canvas hiçbir zaman viewport'un dışına taşıp boşluk göstermesin diye
  /// matrisin translation'ını sınırlar. Görünür bir çerçeve yok; sadece
  /// pan/zoom kenara gelince görünmez şekilde durur.
  Matrix4 _clampMatrix(Matrix4 matrix, Size viewport) {
    final scale = matrix.getMaxScaleOnAxis();
    final scaledWidth = LayoutConstants.canvasWidth * scale;
    final scaledHeight = LayoutConstants.canvasHeight * scale;

    double tx = matrix.storage[12];
    double ty = matrix.storage[13];

    if (scaledWidth <= viewport.width) {
      tx = (viewport.width - scaledWidth) / 2;
    } else {
      tx = tx.clamp(viewport.width - scaledWidth, 0.0);
    }

    if (scaledHeight <= viewport.height) {
      ty = (viewport.height - scaledHeight) / 2;
    } else {
      ty = ty.clamp(viewport.height - scaledHeight, 0.0);
    }

    final result = matrix.clone();
    result.storage[12] = tx;
    result.storage[13] = ty;
    return result;
  }

  void _animateTo(Matrix4 target) {
    _tween = Matrix4Tween(
      begin: _transformController.value.clone(),
      end: target,
    );
    _animController.forward(from: 0);
  }

  /// Canvas'ı viewport'a sığdırır. İlk açılışta anında, sonraki
  /// (pencere yeniden boyutlandığında) durumlarda yumuşak geçişle.
  void _fitCanvas(Size viewport, {bool animate = true}) {
    if (viewport.width <= 0 || viewport.height <= 0) return;

    _viewport = viewport;
    final target = _clampMatrix(_computeFitMatrix(viewport), viewport);
    _fitScale = target.getMaxScaleOnAxis();
    // Fit'in altına asla zoom out edilemesin; kaydırma da bu ölçekte
    // devre dışı bırakılacak (bkz. panEnabled hesaplaması _buildCanvas içinde).
    _minScale = _fitScale;

    if (animate) {
      _animateTo(target);
    } else {
      _transformController.value = target;
    }
  }

  /// Hem "+/-" butonları hem de fare tekerleği birebir aynı şekilde,
  /// viewport'un merkezine göre zoomlar — aralarında davranış farkı olmaz.
  void _applyZoom(double factor, {bool animate = true}) {
    final viewport = _viewport;
    if (viewport == null) return;

    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(_minScale, _maxScale);
    final actualFactor = newScale / currentScale;
    if ((actualFactor - 1).abs() < 0.0001) return;

    final center = Offset(viewport.width / 2, viewport.height / 2);
    final scenePoint = _transformController.toScene(center);

    var target = _transformController.value.clone()
      ..translate(scenePoint.dx, scenePoint.dy)
      ..scale(actualFactor)
      ..translate(-scenePoint.dx, -scenePoint.dy);

    target = _clampMatrix(target, viewport);

    if (animate) {
      _animateTo(target);
    } else {
      _transformController.value = target;
    }
  }

  void _resetZoom() {
    final viewport = _viewport;
    if (viewport != null) {
      _fitCanvas(viewport, animate: true);
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final zoomingIn = event.scrollDelta.dy < 0;
      final factor = zoomingIn ? 1.1 : 1 / 1.1;
      _applyZoom(factor);
    }
  }

  // ─── Şekil değiştirme (çift tıklama) ────────────────────────────────────────

  void _toggleShape(int tableId) {
    setState(() {
      _layouts = _layouts!.map((t) {
        if (t.tableId != tableId) return t;
        return t.copyWith(shape: t.shape == 'circle' ? 'rectangle' : 'circle');
      }).toList();
      _dirty = true;
    });
  }

  // ─── Masa seçimi / detay açma ─────────────────────────────────────────────

  /// Geniş ekranda sağdaki panelde seçili masayı değiştirir; dar ekranda
  /// (mobil) panel için yer olmadığından masa detayını ayrı bir sayfada açar.
  void _handleTableTap(TableLayoutResponseDto t, bool wide) {
    if (!wide) {
      _openFullDetail(t);
      return;
    }
    setState(() {
      _selectedTableId = (_selectedTableId == t.tableId) ? null : t.tableId;
    });
  }

  Future<void> _openFullDetail(TableLayoutResponseDto t) async {
    setState(() => _selectedTableId = t.tableId);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Masa ${t.tableNumber}')),
          body: Consumer(
            builder: (context, ref, _) {
              // Doğrudan provider'ları izliyoruz (ebeveyn ekranın yerel
              // _layouts state'ine değil) ki bu sayfa açıkken bile
              // sunucudan gelen durum/kapasite değişiklikleri anında
              // yansısın.
              final layoutAsync = ref.watch(tableLayoutProvider);
              final tablesAsync = ref.watch(tablesProvider);
              final current =
                  layoutAsync.valueOrNull
                      ?.where((x) => x.tableId == t.tableId)
                      .firstOrNull ??
                  t;
              final fullTable = tablesAsync.valueOrNull
                  ?.where((x) => x.id == t.tableId)
                  .firstOrNull;
              return SingleChildScrollView(
                child: _buildTableInfoAndActions(current, fullTable),
              );
            },
          ),
        ),
      ),
    );

    if (mounted) setState(() => _selectedTableId = null);
  }

  // ─── Kaydet (kat planı pozisyonları) ─────────────────────────────────────────

  Future<void> _save() async {
    if (_layouts == null) return;
    setState(() => _saving = true);
    try {
      final items = _layouts!
          .map(
            (t) => UpdateTableLayoutItemInput(
              tableId: t.tableId,
              positionX: t.positionX,
              positionY: t.positionY,
              width: t.width,
              height: t.height,
              shape: t.shape,
            ),
          )
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
    final numberController = TextEditingController(
      text: existing?.tableNumber.toString() ?? '',
    );
    final capacityController = TextEditingController(
      text: existing?.capacity.toString() ?? '4',
    );

    // Mevcut masanın boyutu canvas'taki layout kaydından okunur; yeni
    // masalar için makul bir varsayılan boyut kullanılır.
    final existingLayout = existing == null
        ? null
        : _layouts?.where((t) => t.tableId == existing.id).firstOrNull;
    final widthController = TextEditingController(
      text: (existingLayout?.width ?? 80).toStringAsFixed(0),
    );
    final heightController = TextEditingController(
      text: (existingLayout?.height ?? 80).toStringAsFixed(0),
    );

    bool isActive = existing?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            existing == null
                ? 'Yeni Masa'
                : 'Masa ${existing.tableNumber} Düzenle',
          ),
          content: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widthController,
                        decoration: const InputDecoration(
                          labelText: 'Genişlik (px)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        decoration: const InputDecoration(
                          labelText: 'Yükseklik (px)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Boyut, kat planı ekranında "Kaydet" butonuna basıldığında uygulanır.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () async {
                final number = int.tryParse(numberController.text);
                final capacity = int.tryParse(capacityController.text);
                final width = double.tryParse(
                  widthController.text,
                )?.clamp(40, 400);
                final height = double.tryParse(
                  heightController.text,
                )?.clamp(40, 400);
                if (number == null || capacity == null) return;

                try {
                  final repository = ref.read(tableRepositoryProvider);
                  if (existing == null) {
                    await repository.createTable(
                      tableNumber: number,
                      capacity: capacity,
                    );
                  } else {
                    await repository.updateTable(
                      id: existing.id,
                      tableNumber: number,
                      capacity: capacity,
                      isActive: isActive,
                    );
                  }

                  if (width != null && height != null) {
                    _pendingSizeOverride = (
                      tableNumber: number,
                      width: width.toDouble(),
                      height: height.toDouble(),
                    );
                  }

                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  _refreshAfterMutation();
                } on ApiException catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(SnackBar(content: Text(e.message)));
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
            child: const Text('Vazgeç'),
          ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
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
            Text(
              table.qrCodeUrl,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kapat'),
          ),
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
                      child: const Text('Vazgeç'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(confirmContext, true),
                      child: const Text('Devam Et'),
                    ),
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
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text(e.message)));
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= _sidebarBreakpoint;

                    // Dar ekranda masa detayı artık ayrı bir sayfada
                    // gösteriliyor; yan panel seçimi burada anlamsız kalır,
                    // temizleyelim (örn. pencere daraltıldığında).
                    if (!wide && _selectedTableId != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedTableId = null);
                      });
                    }

                    // Canvas Expanded ile kalan tüm genişliği alır; sidebar/özet
                    // panel sabit genişlikte olduğundan toplamda her zaman doğru
                    // oranlanır — ayrı yüzde hesabına gerek yoktur.
                    return Row(
                      children: [
                        Expanded(child: _buildCanvas(wide)),
                        if (wide)
                          _selectedTableId != null
                              ? _buildSidebar(tablesAsync.valueOrNull)
                              : _buildSummaryPanel(),
                      ],
                    );
                  },
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
          const Text(
            'Masa Düzeni',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Görünümü sıfırla',
          icon: const Icon(Icons.center_focus_strong_outlined, size: 20),
          onPressed: _resetZoom,
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
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 16),
            label: const Text('Kaydet', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
          _HintChip(
            icon: Icons.touch_app_outlined,
            label: 'Çift tıkla → şekil değiştir',
          ),
          _HintChip(icon: Icons.info_outline, label: 'Tek tıkla → seç'),
          _HintChip(icon: Icons.pinch_outlined, label: 'Pinch → yakınlaştır'),
        ],
      ),
    );
  }

  // ─── Canvas ──────────────────────────────────────────────────────────────────

  Widget _buildCanvas(bool wide) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        // İlk açılışta veya viewport boyutu değiştiğinde (pencere yeniden
        // boyutlandığında) canvas'ı otomatik olarak yeniden sığdır.
        if (_viewport != viewportSize) {
          final target = viewportSize;
          final isFirstFit = _viewport == null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fitCanvas(target, animate: !isFirstFit);
          });
        }

        return Stack(
          children: [
            Listener(
              onPointerSignal: _handlePointerSignal,
              child: ValueListenableBuilder<Matrix4>(
                valueListenable: _transformController,
                builder: (context, matrix, child) {
                  // Sadece fit ölçeğinin üzerine yakınlaştırıldığında
                  // kaydırmaya izin ver; fit halindeyken canvas her zaman
                  // tam ortada sabit kalsın.
                  final scale = matrix.getMaxScaleOnAxis();
                  final panEnabled = scale > _fitScale * 1.01;
                  return InteractiveViewer(
                    transformationController: _transformController,
                    panEnabled: panEnabled,
                    scaleEnabled: true,
                    minScale: _minScale,
                    maxScale: _maxScale,
                    constrained: false,
                    alignment: Alignment.topLeft,
                    boundaryMargin: EdgeInsets.zero,
                    child: child!,
                  );
                },
                child: _buildCanvasContent(
                  LayoutConstants.canvasWidth,
                  LayoutConstants.canvasHeight,
                  wide,
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: _ZoomControls(
                controller: _transformController,
                onZoomIn: () => _applyZoom(1.25),
                onZoomOut: () => _applyZoom(1 / 1.25),
                onReset: _resetZoom,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCanvasContent(double width, double height, bool wide) {
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
                ..._layouts!.map((t) => _buildTableWidget(t, wide)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Masa Widget ──────────────────────────────────────────────────────────────

  Widget _buildTableWidget(TableLayoutResponseDto t, bool wide) {
    final isSelected = _selectedTableId == t.tableId;
    final isDraggingThis = _drag?.tableId == t.tableId;

    return Positioned(
      left: t.positionX.toDouble(),
      top: t.positionY.toDouble(),
      child: GestureDetector(
        onDoubleTap: () => _toggleShape(t.tableId),
        onTap: () => _handleTableTap(t, wide),
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
                      offset: const Offset(0, 6),
                    ),
                  ]
                : isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
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
              child: Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
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
            child: Text(
              'Özet',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statRow('Toplam Masa', total, Colors.grey.shade700),
                const Divider(height: 20),
                statRow(
                  'Müsait',
                  counts[TableStatus.available] ?? 0,
                  Colors.green,
                ),
                statRow(
                  'Dolu',
                  counts[TableStatus.occupied] ?? 0,
                  Colors.orange,
                ),
                statRow(
                  'Rezerve',
                  counts[TableStatus.reserved] ?? 0,
                  Colors.blue,
                ),
                statRow(
                  'Kapalı',
                  counts[TableStatus.outOfService] ?? 0,
                  Colors.grey,
                ),
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

  // ─── Sağ panel (seçili masa: bilgi + CRUD + QR) — geniş ekran ────────────────

  Widget _buildSidebar(List<TableResponseDto>? allTables) {
    final t = _layouts?.where((x) => x.tableId == _selectedTableId).firstOrNull;
    if (t == null) return const SizedBox.shrink();

    // Layout DTO'su isActive/qrCodeUrl içermediği için eşleşen tam masa kaydını buluyoruz.
    final fullTable = allTables?.where((x) => x.id == t.tableId).firstOrNull;

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
                    child: Text(
                      'Masa Bilgisi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
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
            _buildTableInfoAndActions(t, fullTable),
          ],
        ),
      ),
    );
  }

  /// Bilgi satırları + eylem butonları. Hem geniş ekrandaki docked sidebar'da
  /// (_buildSidebar) hem de dar ekranda açılan tam sayfa detayda
  /// (_openFullDetail) aynen kullanılır.
  Widget _buildTableInfoAndActions(
    TableLayoutResponseDto t,
    TableResponseDto? fullTable,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                valueColor: _statusColor(t.status.name),
              ),
              _InfoRow(
                label: 'Şekil',
                value: t.shape == 'circle' ? 'Yuvarlak' : 'Dikdörtgen',
              ),
              _InfoRow(
                label: 'Boyut',
                value:
                    '${t.width.toStringAsFixed(0)} × ${t.height.toStringAsFixed(0)} px',
              ),
              _InfoRow(label: 'Konum', value: '${t.positionX}, ${t.positionY}'),
              if (fullTable != null)
                _InfoRow(
                  label: 'Aktif',
                  value: fullTable.isActive ? 'Evet' : 'Hayır',
                ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                    label: const Text(
                      'Düzenle',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showQrDialog(fullTable),
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text(
                      'QR Göster',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(fullTable),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Sil',
                      style: TextStyle(fontSize: 13, color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Masa detayları yükleniyor…',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Yardımcı ─────────────────────────────────────────────────────────────────

  String _statusLabel(String s) {
    switch (s) {
      case 'Available':
        return 'Boş';
      case 'Occupied':
        return 'Dolu';
      case 'Reserved':
        return 'Rezerve';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Available':
        return Colors.green.shade700;
      case 'Occupied':
        return Colors.red.shade700;
      case 'Reserved':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }
}

// ─── Zoom Kontrolleri ─────────────────────────────────────────────────────────

/// Sağ altta yüzen zoom in / zoom out / ekrana sığdır kontrolleri.
/// Anlık zoom yüzdesini de gösterir.
class _ZoomControls extends StatelessWidget {
  final TransformationController controller;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const _ZoomControls({
    required this.controller,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.18),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(icon: Icons.add, tooltip: 'Yakınlaştır', onTap: onZoomIn),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ValueListenableBuilder<Matrix4>(
              valueListenable: controller,
              builder: (context, matrix, _) {
                final percent = (matrix.getMaxScaleOnAxis() * 100).round();
                return SizedBox(
                  width: 40,
                  child: Text(
                    '%$percent',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _ZoomButton(
            icon: Icons.remove,
            tooltip: 'Uzaklaştır',
            onTap: onZoomOut,
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _ZoomButton(
            icon: Icons.fit_screen_rounded,
            tooltip: 'Ekrana Sığdır',
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      ),
    );
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
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
        ),
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
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
