import 'package:flutter/material.dart';
import 'package:tap_table_customer/features/payment/payment_models.dart';

/// Masanın güncel ödeme durumunu tek satırlık bir özet olarak gösterir.
/// Bölerek Öde aktifse: "2 / 4 Pay Ödendi · ₺450,00 Kaldı"
/// Kısmi (seçerek) ödeme varsa: "₺320,00 Ödendi · ₺180,00 Bekliyor"
/// Hiç ödeme yoksa ya da hesap tamamen kapandıysa hiçbir şey göstermez.
class PaymentProgressBadge extends StatelessWidget {
  final OrderPaymentState state;
  final Color accent;

  const PaymentProgressBadge({
    super.key,
    required this.state,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (state.paidAmount <= 0 || state.isFullyPaid) {
      return const SizedBox.shrink();
    }

    final plan = state.activeSplitPlan;
    final String label;
    final IconData icon;

    if (plan != null) {
      label =
          '${plan.sharesPaid} / ${plan.totalPeople} Pay Ödendi · '
          '₺${state.remainingAmount.toStringAsFixed(2)} Kaldı';
      icon = Icons.call_split;
    } else {
      label =
          '₺${state.paidAmount.toStringAsFixed(2)} Ödendi · '
          '₺${state.remainingAmount.toStringAsFixed(2)} Bekliyor';
      icon = Icons.payments_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
