import 'package:dio/dio.dart';
import 'env.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio _dio;

  ApiClient._(this._dio);

  factory ApiClient({String? baseUrl, String? token}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            try {
              final prefs = await SharedPreferences.getInstance();
              final refreshToken = prefs.getString('refresh_token');
              final deviceId = prefs.getString('device_id');
              if (refreshToken != null && deviceId != null) {
                final refreshResp = await dio.post(
                  '/auth/refresh',
                  data: {'refreshToken': refreshToken, 'deviceId': deviceId},
                );
                final data = refreshResp.data as Map;
                final newToken = data['token'] as String?;
                final newRt = data['refreshToken'] as String?;
                if (newToken != null) {
                  await prefs.setString('auth_token', newToken);
                  if (newRt != null) {
                    await prefs.setString('refresh_token', newRt);
                  }
                  final opts = e.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $newToken';
                  final clone = await dio.fetch(opts);
                  return handler.resolve(clone);
                }
              }
            } catch (_) {}
          }
          return handler.next(e);
        },
      ),
    );
    return ApiClient._(dio);
  }

  Dio get dio => _dio;
}
