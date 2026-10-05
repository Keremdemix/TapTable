class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  factory ApiException.fromDioError(dynamic error) {
     print('DIO ERROR → type: ${error.type}, message: ${error.message}, response: ${error.response}');

    try {
      final data = error.response?.data;

    String message = 'Bilinmeyen bir hata oluştu.';

    if (data is Map) {
      message = data['error'] ??
          data['message'] ??
          data['detail'] ??
          data['title'] ??
          message;
    }

    return ApiException(
      statusCode: error.response?.statusCode ?? 500,
      message: message,
    );
  } catch (e) {
    print(e);
    return ApiException(
      statusCode: 500,
      message: 'Sunucuya bağlanılamadı.',
    );
  }
}

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isBadRequest => statusCode == 400;
  
  @override
  String toString() => message; 
}