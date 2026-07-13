import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_customer/features/payment/checkout_pending_screen.dart';
import 'package:tap_table_customer/features/payment/payment_models.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/session/session_provider.dart';
import 'payment_provider.dart';

class SplitPaymentScreen extends ConsumerStatefulWidget {
  final Color primary;
  final Color accent;

  const SplitPaymentScreen({
    super.key,
    required this.primary,
    required this.accent,
  });

  @override
  ConsumerState<SplitPaymentScreen> createState() => _SplitPaymentScreenState();
}

class _SplitPaymentScreenState extends ConsumerState<SplitPaymentScreen> {
  int _totalPeople = 2;
  int _sharesToPay = 1;
  bool _busy = false;

  Future<void> _createPlan(int tableId) async {
    setState(() => _busy = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final sessionKey = await ref.read(sessionStorageProvider).getToken();
      await apiClient.createSplitPlan(
        tableId,
        sessionKey: sessionKey!,
        totalPeople: _totalPeople,
      );
      ref.invalidate(paymentStateProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Plan oluşturulamadı: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelPlan(int tableId, int planId) async {
    setState(() => _busy = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final sessionKey = await ref.read(sessionStorageProvider).getToken();
      await apiClient.cancelSplitPlan(tableId, planId, sessionKey: sessionKey!);
      ref.invalidate(paymentStateProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Plan iptal edilemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payShare(int tableId, int planId) async {
    setState(() => _busy = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final sessionKey = await ref.read(sessionStorageProvider).getToken();

      final json = await apiClient.paySplitShare(
        tableId,
        planId,
        sessionKey: sessionKey!,
        shares: _sharesToPay,
      );

      final checkout = IyzicoCheckoutResult.fromJson(json);
      await launchUrl(
        Uri.parse(checkout.paymentPageUrl),
        webOnlyWindowName: '_blank',
      );

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CheckoutPendingScreen(
              primary: widget.primary,
              accent: widget.accent,
              paymentId: checkout.paymentId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ödeme başlatılamadı: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(customerSessionProvider);
    final stateAsync = ref.watch(paymentStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bölerek Öde')),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Oturum bilgisi alınamadı.')),
        data: (session) => stateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Ödeme bilgisi alınamadı.')),
          data: (state) {
            if (state == null) {
              return const Center(child: Text('Ödeme bilgisi alınamadı.'));
            }

            final plan = state.activeSplitPlan;

            if (plan == null || !plan.isActive) {
              // ── Henüz plan yok — kişi sayısı seçip oluştur ──
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Kalan tutarı kaç kişiye eşit bölmek istersiniz?',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kalan Tutar: ₺${state.remainingAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _totalPeople <= 2
                              ? null
                              : () => setState(() => _totalPeople--),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_totalPeople kişi',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => _totalPeople++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Kişi başı ≈ ₺${(state.remainingAmount / _totalPeople).toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.accent,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _busy
                          ? null
                          : () => _createPlan(session.tableId),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Bölüşümü Başlat'),
                    ),
                  ],
                ),
              );
            }

            // ── Aktif plan var — pay öde / iptal et ──
            final remainingShares = plan.remainingShares;
            _sharesToPay = _sharesToPay.clamp(
              1,
              remainingShares == 0 ? 1 : remainingShares,
            );

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.primary.withOpacity(.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${plan.totalPeople} kişiye bölündü',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${plan.sharesPaid} / ${plan.totalPeople} pay ödendi',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kişi başı: ₺${plan.amountPerPerson.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: widget.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (remainingShares > 0) ...[
                    Text(
                      'Kaç pay ödemek istersiniz?',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _sharesToPay <= 1
                              ? null
                              : () => setState(() => _sharesToPay--),
                        ),
                        Text(
                          '$_sharesToPay',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _sharesToPay >= remainingShares
                              ? null
                              : () => setState(() => _sharesToPay++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Ödenecek: ₺${(plan.amountPerPerson * _sharesToPay).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.accent,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _busy
                          ? null
                          : () => _payShare(session.tableId, plan.id),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Payımı Öde'),
                    ),
                  ] else
                    const Center(
                      child: Text('Tüm paylar ödendi, onay bekleniyor.'),
                    ),
                  if (plan.sharesPaid == 0) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _cancelPlan(session.tableId, plan.id),
                      child: const Text('Bölüşümü İptal Et'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
