import 'package:dio/dio.dart';
import '../session/session_storage.dart';
import 'api_exception.dart';

class ApiClient {
  final Dio dio;
  final SessionStorage _sessionStorage;

  ApiClient(this._sessionStorage)
    : dio = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://localhost:5014/api',
          ),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!options.path.contains('/customer/session')) {
            final token = await _sessionStorage.getToken();
            if (token != null) {
              options.headers['X-QR-Token'] = token;
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await dio.get(path, queryParameters: query);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final res = await dio.post(path, data: data);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 204 No Content dönen endpoint'ler için (örn. bölüşüm planı iptali).
  Future<void> postNoContent(String path, {dynamic data}) async {
    try {
      await dio.post(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> resolveSession(String token) {
    return get('/public/customer/session', query: {'token': token});
  }

  Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    String? note,
  }) {
    return post('/public/orders', data: {'items': items, 'note': note});
  }

  // ── Ödeme ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPaymentState(int tableId, String sessionKey) {
    return get(
      '/public/payments/$tableId/state',
      query: {'sessionKey': sessionKey},
    );
  }

  Future<Map<String, dynamic>> createSplitPlan(
    int tableId, {
    required String sessionKey,
    required int totalPeople,
  }) {
    return post(
      '/public/payments/$tableId/split-plan',
      data: {'sessionKey': sessionKey, 'totalPeople': totalPeople},
    );
  }

  Future<void> cancelSplitPlan(
    int tableId,
    int planId, {
    required String sessionKey,
  }) {
    return postNoContent(
      '/public/payments/$tableId/split-plan/$planId/cancel',
      data: {'sessionKey': sessionKey},
    );
  }

  Future<Map<String, dynamic>> paySplitShare(
    int tableId,
    int planId, {
    required String sessionKey,
    required int shares,
  }) {
    return post(
      '/public/payments/$tableId/split-plan/$planId/pay-share',
      data: {'sessionKey': sessionKey, 'shares': shares},
    );
  }

  Future<Map<String, dynamic>> paySelectedItems(
    int tableId, {
    required String sessionKey,
    required List<Map<String, dynamic>> items,
  }) {
    return post(
      '/public/payments/$tableId/pay-selected',
      data: {'sessionKey': sessionKey, 'items': items},
    );
  }

  Future<Map<String, dynamic>> createIyzicoCheckout(
    int tableId, {
    required String sessionKey,
  }) {
    return post(
      '/public/payments/$tableId/iyzico-checkout',
      data: {'sessionKey': sessionKey},
    );
  }

  Future<Map<String, dynamic>> getPaymentStatus(
    int tableId,
    int paymentId,
    String sessionKey,
  ) {
    return get(
      '/public/payments/$tableId/payment-status/$paymentId',
      query: {'sessionKey': sessionKey},
    );
  }
}
