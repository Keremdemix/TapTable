import 'dart:math' as math;

//import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_staff/core/constants/layout_constants.dart';
import 'package:tap_table_staff/features/tables/data/table_models.dart';
import 'package:tap_table_staff/features/waiter/application/ready_alert_provider.dart';
import 'package:tap_table_staff/features/waiter/presentation/order_display.dart';
import '../../auth/application/auth_providers.dart';
import '../../orders/application/order_providers.dart';
import '../../orders/data/order_models.dart';
import '../../tables/application/table_providers.dart';
import '../../tables/data/table_layout_models.dart';
import '../../tables/presentation/table_shape_widget.dart';
import 'waiter_item_picker_screen.dart';
import 'waiter_payment_screen.dart';
import 'waiter_table_detail_screen.dart';

/// Sidebar'ı gösterecek kadar geniş ekranlar için eşik. Altında tam sayfa push.
const double _sidebarBreakpoint = 700;

class WaiterHomeScreen extends ConsumerStatefulWidget {
  const WaiterHomeScreen({super.key});

  @override
  ConsumerState<WaiterHomeScreen> createState() => _WaiterHomeScreenState();
}

class _WaiterHomeScreenState extends ConsumerState<WaiterHomeScreen>
    with SingleTickerProviderStateMixin {
  TableLayoutResponseDto? _selected;

  final TransformationController _controller = TransformationController();

  late final AnimationController _animController;
  late final CurvedAnimation _curvedAnim;
  Matrix4Tween? _tween;

  Offset? _doubleTapPosition;

  // Son fit edilen viewport boyutu ve o anki "ekrana sığdır" ölçeği.
  Size? _viewport;
  double _fitScale = 1.0;

  static const double _absoluteMinScale = 0.05;
  static const double _maxScale = 2.0;

  // Kaydırma (pan) sadece kullanıcı "ekrana sığdır" ölçeğinin üzerine
  // yakınlaştığında anlamlı; bu yüzden minScale her zaman güncel fit
  // ölçeğine eşitlenir. Böylece kullanıcı fit'in altına asla inemez ve
  // fit halindeyken kaydırma her zaman tam ortalanmış kalır.
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
        _controller.value = tween.evaluate(_curvedAnim);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDetail(
    BuildContext context,
    TableLayoutResponseDto t,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WaiterTableDetailScreen(
          tableId: t.tableId,
          tableNumber: t.tableNumber,
        ),
      ),
    );
    ref.invalidate(tableLayoutProvider);
    if (mounted && _selected != null) {
      ref.invalidate(tableActiveOrderProvider(_selected!.tableId));
    }
  }

  void _handleTableTap(
    BuildContext context,
    TableLayoutResponseDto t,
    bool wide,
  ) {
    if (!wide) {
      _openDetail(context, t);
      return;
    }
    setState(() {
      _selected = (_selected?.tableId == t.tableId) ? null : t;
    });
  }

  // ---------------------------------------------------------------------
  // Zoom / Pan
  // ---------------------------------------------------------------------

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
    _tween = Matrix4Tween(begin: _controller.value.clone(), end: target);
    _animController.forward(from: 0);
  }

  /// Canvas'ı viewport'a sığdırır. İlk açılışta anında, sonraki
  /// (sidebar açma/kapama gibi) durumlarda yumuşak geçişle.
  void _fitCanvas(Size viewport, {bool animate = true}) {
    if (viewport.width <= 0 || viewport.height <= 0) return;

    _viewport = viewport;
    final target = _clampMatrix(_computeFitMatrix(viewport), viewport);
    _fitScale = target.getMaxScaleOnAxis();
    // Fit'in altına asla zoom out edilemesin; kaydırma da bu ölçekte
    // devre dışı bırakılacak (bkz. panEnabled hesaplaması build() içinde).
    _minScale = _fitScale;

    if (animate) {
      _animateTo(target);
    } else {
      _controller.value = target;
    }
  }

  /// [viewportPosition] etrafında (o nokta ekranda sabit kalacak şekilde)
  /// yakınlaştırma/uzaklaştırma yapar.
  void _zoomAtPoint(
    Offset viewportPosition,
    double factor, {
    bool animate = false,
  }) {
    final viewport = _viewport;
    if (viewport == null) return;

    final currentScale = _controller.value.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(_minScale, _maxScale);
    final actualFactor = newScale / currentScale;
    if ((actualFactor - 1).abs() < 0.0001) return;

    final scenePoint = _controller.toScene(viewportPosition);
    var target = _controller.value.clone()
      ..translate(scenePoint.dx, scenePoint.dy)
      ..scale(actualFactor)
      ..translate(-scenePoint.dx, -scenePoint.dy);

    target = _clampMatrix(target, viewport);

    if (animate) {
      _animateTo(target);
    } else {
      _controller.value = target;
    }
  }

  /// Zoom butonları viewport'un tam ortasına göre yakınlaştırır/uzaklaştırır.
  void _zoomFromCenter(double factor) {
    final viewport = _viewport;
    if (viewport == null) return;
    final center = Offset(viewport.width / 2, viewport.height / 2);
    _zoomAtPoint(center, factor, animate: true);
  }

  void _resetZoom() {
    final viewport = _viewport;
    if (viewport != null) {
      _fitCanvas(viewport, animate: true);
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Fare tekerleği artık imlece göre değil, tıpkı sol alttaki
      // +/- butonları gibi viewport'un merkezine göre zoomluyor. Böylece
      // iki yöntem de birebir aynı ölçeğe, aynı şekilde ulaşıyor.
      final zoomingIn = event.scrollDelta.dy < 0;
      final factor = zoomingIn ? 1.1 : 1 / 1.1;
      _zoomFromCenter(factor);
    }
  }

  void _handleDoubleTap() {
    final position = _doubleTapPosition;
    if (position == null) return;

    final currentScale = _controller.value.getMaxScaleOnAxis();
    final isZoomedIn = currentScale > _fitScale * 1.15;

    if (isZoomedIn) {
      _resetZoom();
    } else {
      _zoomAtPoint(position, 2.2, animate: true);
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(tableLayoutProvider);
    final flashingTableIds = ref.watch(readyAlertProvider);
    final tableAlertStates = ref.watch(tableAlertStateProvider); // ← YENİ

    return Scaffold(
      appBar: AppBar(
        title: const Text('Masalar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted)
                Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _sidebarBreakpoint;
          final sidebarOpen = wide && _selected != null;
          final canvasAreaWidth = sidebarOpen
              ? constraints.maxWidth - 340
              : constraints.maxWidth;
          final viewportSize = Size(canvasAreaWidth, constraints.maxHeight);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tableLayoutProvider),
            child: layoutAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Hata: $err')),
              data: (layouts) {
                if (layouts.isEmpty) {
                  return const Center(child: Text('Henüz masa eklenmedi.'));
                }

                // Sidebar'da seçili masa artık layout listesinde yoksa (silinmiş olabilir) temizle.
                if (_selected != null &&
                    !layouts.any((t) => t.tableId == _selected!.tableId)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selected = null);
                  });
                }

                // Seçili masanın layout snapshot'ı (_selected) her build'de
                // güncel listeyle senkron tutulur. Böylece ödeme/ekleme gibi
                // işlemlerden sonra provider tazelendiğinde, sidebar'a
                // geçirilen masa nesnesi de (renk/duruma bakılmadan) güncel
                // kalır — kullanıcı ekrandan çıkıp tekrar girmek zorunda
                // kalmaz.
                if (_selected != null) {
                  final fresh = layouts.firstWhere(
                    (t) => t.tableId == _selected!.tableId,
                    orElse: () => _selected!,
                  );
                  if (!identical(fresh, _selected)) {
                    _selected = fresh;
                  }
                }

                // İlk açılışta veya viewport boyutu değiştiğinde (sidebar
                // açılıp kapandığında, pencere yeniden boyutlandığında)
                // canvas'ı otomatik olarak yeniden sığdır.
                if (_viewport != viewportSize) {
                  final target = viewportSize;
                  final isFirstFit = _viewport == null;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _fitCanvas(target, animate: !isFirstFit);
                    }
                  });
                }

                return Row(
                  children: [
                    Expanded(
                      child: ClipRect(
                        child: Stack(
                          children: [
                            Listener(
                              onPointerSignal: _handlePointerSignal,
                              child: GestureDetector(
                                onDoubleTapDown: (details) =>
                                    _doubleTapPosition = details.localPosition,
                                onDoubleTap: _handleDoubleTap,
                                child: ValueListenableBuilder<Matrix4>(
                                  valueListenable: _controller,
                                  builder: (context, matrix, child) {
                                    // Sadece fit ölçeğinin üzerine
                                    // yakınlaştırıldığında kaydırmaya izin
                                    // ver; fit halindeyken canvas her zaman
                                    // tam ortada sabit kalsın.
                                    final scale = matrix.getMaxScaleOnAxis();
                                    final panEnabled = scale > _fitScale * 1.01;
                                    return InteractiveViewer(
                                      transformationController: _controller,
                                      panEnabled: panEnabled,
                                      scaleEnabled: true,
                                      minScale: _minScale,
                                      maxScale: _maxScale,
                                      constrained: false,
                                      boundaryMargin: EdgeInsets.zero,
                                      child: child!,
                                    );
                                  },
                                  child: SizedBox(
                                    width: LayoutConstants.canvasWidth,
                                    height: LayoutConstants.canvasHeight,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: layouts.map((t) {
                                        final isSelected =
                                            wide &&
                                            _selected?.tableId == t.tableId;
                                        final isFlashing = flashingTableIds
                                            .contains(t.tableId);
                                        return Positioned(
                                          left: t.positionX.toDouble(),
                                          top: t.positionY.toDouble(),
                                          child: GestureDetector(
                                            onTap: () => _handleTableTap(
                                              context,
                                              t,
                                              wide,
                                            ),
                                            child: _ReadyGlow(
                                              isFlashing: isFlashing,
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 120,
                                                ),
                                                decoration: BoxDecoration(
                                                  boxShadow: isSelected
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.blue
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
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
                                                  alertState:
                                                      tableAlertStates[t
                                                          .tableId] ??
                                                      TableAlertState.none,
                                                  hasUnpaidOrder:
                                                      t.status ==
                                                      TableStatus.occupied,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 16,
                              bottom: 16,
                              child: _ZoomControls(
                                controller: _controller,
                                onZoomIn: () => _zoomFromCenter(1.25),
                                onZoomOut: () => _zoomFromCenter(1 / 1.25),
                                onReset: _resetZoom,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (sidebarOpen)
                      _TableSidebar(
                        table: _selected!,
                        onClose: () => setState(() => _selected = null),
                        onOpenFullDetail: () =>
                            _openDetail(context, _selected!),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Mutfakta hazır olarak işaretlenmiş masaların etrafında yanıp sönen
/// turuncu bir hâle (glow) gösterir. O masadaki tüm Ready ürünler Served
/// olana kadar sürer (bkz. ReadyAlertNotifier).
class _ReadyGlow extends StatefulWidget {
  final bool isFlashing;
  final Widget child;

  const _ReadyGlow({required this.isFlashing, required this.child});

  @override
  State<_ReadyGlow> createState() => _ReadyGlowState();
}

class _ReadyGlowState extends State<_ReadyGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFlashing) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0..1
        final glowOpacity = 0.35 + (t * 0.45);
        final glowBlur = 10 + (t * 14);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: glowOpacity),
                blurRadius: glowBlur,
                spreadRadius: 2 + (t * 3),
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

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
      shadowColor: Colors.black.withValues(alpha: 0.18),
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

class _TableSidebar extends ConsumerStatefulWidget {
  final TableLayoutResponseDto table;
  final VoidCallback onClose;
  final VoidCallback onOpenFullDetail;

  const _TableSidebar({
    required this.table,
    required this.onClose,
    required this.onOpenFullDetail,
  });

  @override
  ConsumerState<_TableSidebar> createState() => _TableSidebarState();
}

class _TableSidebarState extends ConsumerState<_TableSidebar> {
  bool _serving = false;

  Future<void> _serveReadyItems() async {
    setState(() => _serving = true);
    try {
      await ref
          .read(orderRepositoryProvider)
          .serveReadyItems(widget.table.tableId);
      ref.invalidate(tableActiveOrderProvider(widget.table.tableId));
      // Poll'u beklemeden masa parlamasını hemen kapat.
      await ref.read(readyAlertProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Teslim işlemi başarısız: $e')));
      }
    } finally {
      if (mounted) setState(() => _serving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(
      tableActiveOrderProvider(widget.table.tableId),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Masa ${widget.table.tableNumber}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: orderAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Hata: $err')),
              data: (order) {
                if (order == null) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 80),
                      const Center(child: Text('Bu masada aktif sipariş yok.')),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WaiterItemPickerScreen(
                                tableId: widget.table.tableId,
                              ),
                            ),
                          );

                          ref.invalidate(
                            tableActiveOrderProvider(widget.table.tableId),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Sipariş Oluştur'),
                      ),
                    ],
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ActiveOrderContent(
                      order: order,
                      serving: _serving,
                      onServeReadyItems: _serveReadyItems,
                      actions: [
                        FilledButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaiterItemPickerScreen(
                                  tableId: widget.table.tableId,
                                ),
                              ),
                            );

                            ref.invalidate(
                              tableActiveOrderProvider(widget.table.tableId),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Ürün Ekle'),
                        ),

                        const SizedBox(height: 8),

                        OutlinedButton.icon(
                          onPressed:
                              order.paymentStatus == OrderPaymentStatus.paid
                              ? null
                              : () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          WaiterPaymentScreen(order: order),
                                    ),
                                  );

                                  ref.invalidate(
                                    tableActiveOrderProvider(
                                      widget.table.tableId,
                                    ),
                                  );

                                  ref.invalidate(tableLayoutProvider);
                                },
                          icon: const Icon(Icons.payments),
                          label: Text(
                            order.paymentStatus == OrderPaymentStatus.paid
                                ? 'Ödendi'
                                : 'Ödeme Al',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: widget.onOpenFullDetail,
                icon: const Icon(Icons.open_in_full, size: 16),
                label: const Text(
                  'Tam Ekran Detay',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
