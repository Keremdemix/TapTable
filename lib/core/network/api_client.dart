import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage _tokenStorage;

  ApiClient(this._tokenStorage)
      : dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // /public/ ile başlayan endpoint'ler token istemiyor
        if (!options.path.contains('/public/')) {
          final token = await _tokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final retryRequest = await _retry(error.requestOptions);
            return handler.resolve(retryRequest);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      await _tokenStorage.saveTokens(
        accessToken: response.data['accessToken'],
        refreshToken: response.data['refreshToken'],
      );
      return true;
    } catch (_) {
      await _tokenStorage.clear();
      return false;
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _tokenStorage.getAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: {...requestOptions.headers, 'Authorization': 'Bearer $token'},
    );
    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
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

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    try {
      final res = await dio.put(path, data: data);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> patch(String path, {dynamic data}) async {
    try {
      final res = await dio.patch(path, data: data);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await dio.delete(path);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? query}) async {
  try {
    final res = await dio.get(path, queryParameters: query);
    return res.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
}
}