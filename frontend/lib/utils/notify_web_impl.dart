import 'dart:html' as html;

Future<void> showWebNotification(String title, String body) async {
  try {
    final perm = await html.Notification.requestPermission();
    if (perm == 'granted') {
      html.Notification(title, body: body, icon: '/favicon.png');
      // Also log for debugging
      // ignore: avoid_print
      print('[notify] Web notification shown: ' + title + ' - ' + body);
    } else {
      // ignore: avoid_print
      print('[notify] Notification permission not granted: ' + perm);
    }
  } catch (e) {
    // ignore: avoid_print
    print('[notify] Error showing web notification: ' + e.toString());
  }
}
