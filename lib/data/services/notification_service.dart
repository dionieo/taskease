// import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Hanya di web
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 🌐 Web: pakai browser notification
    if (kIsWeb) {
      if (html.Notification.supported) {
        await html.Notification.requestPermission();
      }
      print("✅ Notifikasi web diinisialisasi");
      return;
    }

    // 📱 Android/iOS: pakai FlutterLocalNotifications
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _notifications.initialize(initSettings);
    tz.initializeTimeZones();
    print("✅ Notifikasi lokal diinisialisasi");
  }

  /// Tampilkan notifikasi langsung atau beberapa jam sebelum deadline
  static Future<void> showNotification({
    required String title,
    required String body,
    DateTime? scheduledTime,
    int reminderHoursBefore = 0, // default: tepat saat deadline
  }) async {
    // 🌐 Web version
    if (kIsWeb) {
      if (html.Notification.supported &&
          html.Notification.permission == "granted") {
        html.Notification(title, body: body);
      }
      return;
    }

    // 📱 Mobile version
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_channel',
        'Task Reminder',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    // Jika tidak ada scheduledTime -> tampilkan segera
    if (scheduledTime == null) {
      await _notifications.show(0, title, body, details);
      return;
    }

    // Hitung waktu notifikasi berdasarkan scheduledTime dan reminderHoursBefore
    DateTime notifyTime = scheduledTime.subtract(Duration(hours: reminderHoursBefore));

    // Jangan jadwalkan notifikasi di masa lalu
    if (notifyTime.isBefore(DateTime.now())) {
      notifyTime = DateTime.now().add(const Duration(seconds: 5));
    }

    await _notifications.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.from(notifyTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
