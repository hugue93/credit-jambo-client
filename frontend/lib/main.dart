import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/auth_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: system shows notification for messages with notification payload in background
  // Optionally handle data-only messages here.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await NotificationService.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n != null) {
        // Show a local notification on Android when app is foreground
        NotificationService.showLocal(msg);
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(n.title ?? n.body ?? 'Notification')),
        );
      }
    });
  } catch (_) {}
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('auth_token');
  runApp(
    ProviderScope(
      overrides: [authTokenProvider.overrideWith((ref) => savedToken)],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF05A84A); // from logo
    final base = ThemeData(useMaterial3: true, colorSchemeSeed: brandGreen);
    final theme = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: brandGreen,
        secondary: brandGreen,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF05A84A)),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    );
    return MaterialApp.router(
      title: 'Credit Jambo Client',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: appRouter,
      scaffoldMessengerKey: _scaffoldMessengerKey,
    );
  }
}
