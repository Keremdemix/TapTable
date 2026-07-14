import '../../../core/network/api_client.dart';
import 'payment_models.dart';

class PaymentRepository {
  final ApiClient _apiClient;
  PaymentRepository(this._apiClient);

  Future<PaymentResponseDto> recordManualPayment({
    required int orderId,
    required double amount,
    required PaymentMethodType method,
  }) async {
    final json = await _apiClient.post('/payments/manual', data: {
      'orderId': orderId,
      'amount': amount,
      'method': _methodName(method),
    });
    return PaymentResponseDto.fromJson(json);
  }

  Future<List<PaymentResponseDto>> getPaymentsForOrder(int orderId) async {
    final list = await _apiClient.getList('/payments/order/$orderId');
    return list.map((j) => PaymentResponseDto.fromJson(j as Map<String, dynamic>)).toList();
  }

  String _methodName(PaymentMethodType method) => switch (method) {
        PaymentMethodType.cash => 'Cash',
        PaymentMethodType.card => 'Card',
        PaymentMethodType.iyzico => 'Iyzico',
      };
}