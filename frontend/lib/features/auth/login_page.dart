import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/device_id.dart';
import 'auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../services/api_client.dart';
import '../../utils/notify.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _canRegisterDevice = false;
  bool _pendingVerification = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deviceId = await DeviceIdService.getOrCreate();
      final repo = ref.read(authRepositoryProvider);
      final resp = await repo.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        deviceId: deviceId,
      );
      final token = (resp.data as Map)['token'] as String?;
      final rt = (resp.data as Map)['refreshToken'] as String?;
      if (token == null) throw Exception('No token');
      ref.read(authTokenProvider.notifier).state = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      if (rt != null) await prefs.setString('refresh_token', rt);
      // Save deviceId for refresh token flow on web/mobile
      await prefs.setString('device_id', deviceId);
      // Capture and send FCM token (optional in dev)
      final fcm = await NotificationService.getFcmToken();
      // ignore: avoid_print
      print('[login] Retrieved FCM token: ${fcm ?? 'null'}');
      if (fcm != null && fcm.isNotEmpty) {
        try {
          final client = ApiClient(token: token);
          await client.dio.post('/devices/push-token', data: {'fcmToken': fcm});
          // ignore: avoid_print
          print('[login] Push token registered successfully');
        } catch (e) {
          // ignore: avoid_print
          print('[login] Failed to register push token: $e');
        }
      } else {
        // ignore: avoid_print
        print('[login] Empty FCM token, skipping registration');
      }
      // Show a local web notification as immediate UX feedback
      await showWebNotification('Login successful', 'Welcome back');
      if (mounted) {
        context.pushReplacement('/dashboard');
      }
    } catch (e) {
      String message = e.toString();
      try {
        // Try to extract backend error (Dio)
        // ignore: avoid_dynamic_calls
        final data = (e as dynamic).response?.data;
        if (data is Map && data['message'] is String) {
          message = data['message'] as String;
        }
      } catch (_) {}
      final lower = message.toLowerCase();
      setState(() {
        _error = message;
        _canRegisterDevice = lower.contains('not registered');
        _pendingVerification = lower.contains('not verified');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 600;
    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordCtrl,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (v) =>
                (v == null || v.length < 8) ? 'Min 8 chars' : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.lock_open),
              onPressed: _loading ? null : _submit,
              label: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Login'),
            ),
          ),
          if (_pendingVerification)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Device pending verification. You will be able to login once an admin approves it.',
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _loading ? null : () => context.push('/register'),
                child: const Text('Create account'),
              ),
              TextButton(
                onPressed: _loading ? null : () => context.push('/forgot'),
                child: const Text('Forgot password?'),
              ),
              if (_canRegisterDevice)
                TextButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          try {
                            final deviceId =
                                await DeviceIdService.getOrCreate();
                            final repo = ref.read(authRepositoryProvider);
                            await repo.registerDeviceByEmail(
                              email: _emailCtrl.text.trim(),
                              deviceId: deviceId,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Device registered. Await admin verification.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  child: const Text('Register this device'),
                ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 520 : 380),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/images/logo.png', height: 28),
                          const SizedBox(width: 8),
                          const Text(
                            '',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      content,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
