import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../orders/data/order_models.dart';
import '../../payments/application/payment_providers.dart';
import '../../payments/data/payment_models.dart';

class WaiterPaymentScreen extends ConsumerStatefulWidget {
  final OrderResponseDto order;
  const WaiterPaymentScreen({super.key, required this.order});

  @override
  ConsumerState<WaiterPaymentScreen> createState() =>
      _WaiterPaymentScreenState();
}

class _WaiterPaymentScreenState extends ConsumerState<WaiterPaymentScreen> {
  late final TextEditingController _amountController;
  PaymentMethodType _method = PaymentMethodType.cash;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.order.totalPrice.toStringAsFixed(2),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Geçerli bir tutar girin.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .recordManualPayment(
            orderId: widget.order.id,
            amount: amount,
            method: _method,
          );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme Al')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sipariş Toplamı: ₺${widget.order.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Alınan Tutar (₺)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ödeme Yöntemi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PaymentMethodType>(
              segments: const [
                ButtonSegment(
                  value: PaymentMethodType.cash,
                  label: Text('Nakit'),
                  icon: Icon(Icons.payments),
                ),
                ButtonSegment(
                  value: PaymentMethodType.card,
                  label: Text('Kart (POS)'),
                  icon: Icon(Icons.credit_card),
                ),
              ],
              selected: {_method},
              onSelectionChanged: (selection) =>
                  setState(() => _method = selection.first),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Ödemeyi Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
