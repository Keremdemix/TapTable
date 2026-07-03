import 'package:dio/dio.dart';
import '../session/session_storage.dart';
import 'api_exception.dart';

class ApiClient {
  final Dio dio;
  final SessionStorage _sessionStorage;

  ApiClient(this._sessionStorage)
      : dio = Dio(BaseOptions(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://localhost:5014/api',
          ),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Sadece GET isteklerine sessionKey query param olarak eklenir
        // (backend GET endpoint'leri sessionKey'i query'den okuyor).
        // POST body'leri (PlaceOrderRequestDto vb.) sessionKey'i kendi
        // içinde taşıdığı için burada dokunulmuyor.
        if (options.method == 'GET') {
          final sessionKey = await _sessionStorage.getSessionKey();
          if (sessionKey != null && !options.queryParameters.containsKey('sessionKey')) {
            options.queryParameters['sessionKey'] = sessionKey;
          }
        }
        handler.next(options);
      },
    ));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
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
  Future<Map<String, dynamic>> placeOrder({
    required int tableId,
    required String sessionKey,
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    return post('/public/orders/$tableId', data: {
      'sessionKey': sessionKey,
      'items': items,
      'note': note,
    });
  }
}