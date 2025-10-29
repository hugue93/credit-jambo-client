import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  static const _key = 'device_id';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;

    String generated;
    if (kIsWeb) {
      generated = _randomId();
    } else {
      final info = DeviceInfoPlugin();
      try {
        final android = await info.androidInfo;
        generated = android.id;
      } catch (_) {
        generated = _randomId();
      }
    }
    await prefs.setString(_key, generated);
    return generated;
  }

  static String _randomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(24, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
