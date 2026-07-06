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
        // /public/customer/session hariç tüm isteklere token header'ı eklenir.
        // O endpoint'in kendi token'ını query'de zaten taşıdığı için hariç tutuluyor.
        if (!options.path.contains('/customer/session')) {
          final token = await _sessionStorage.getToken();
          if (token != null) {
            options.headers['X-QR-Token'] = token;
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

  Future<Map<String, dynamic>> resolveSession(String token) {
    return get('/public/customer/session', query: {'token': token});
  }

  Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    String? note,
  }) {
    return post('/public/orders', data: {'items': items, 'note': note});
  }
}