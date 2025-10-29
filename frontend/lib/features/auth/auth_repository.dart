import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

final authTokenProvider = StateProvider<String?>((ref) => null);

class AuthRepository {
  AuthRepository(this._client);
  final ApiClient _client;

  Future<Response<dynamic>> login({
    required String email,
    required String password,
    required String deviceId,
  }) {
    return _client.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password, 'deviceId': deviceId},
    );
  }

  Future<Response<dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String deviceId,
  }) {
    return _client.dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'deviceId': deviceId,
      },
    );
  }

  Future<Response<dynamic>> refresh({
    required String refreshToken,
    required String deviceId,
  }) {
    return _client.dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken, 'deviceId': deviceId},
    );
  }

  Future<Response<dynamic>> registerDeviceByEmail({
    required String email,
    required String deviceId,
  }) {
    return _client.dio.post(
      '/devices/register-by-email',
      data: {'email': email, 'deviceId': deviceId},
    );
  }

  Future<Response<dynamic>> requestPasswordReset({required String email}) {
    return _client.dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<Response<dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) {
    return _client.dio.post(
      '/auth/reset-password',
      data: {'email': email, 'token': token, 'newPassword': newPassword},
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final token = ref.watch(authTokenProvider);
  return ApiClient(token: token);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthRepository(client);
});
