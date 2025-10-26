// import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
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
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta')); // Set timezone lokal
    print("✅ Notifikasi lokal diinisialisasi");
  }

  /// Minta permission notifikasi (Android 13+ / iOS)
  static Future<bool> requestPermission() async {
    if (kIsWeb) return true;

    try {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        print('✅ Notification permission already granted');
        return true;
      }

      final result = await Permission.notification.request();

      if (result.isGranted) {
        print('✅ Notification permission granted');
        return true;
      }

      if (result.isPermanentlyDenied) {
        // Jika user menolak permanen, arahkan ke settings agar bisa enable manual
        print('⚠️ Notification permission permanently denied');
        await openAppSettings();
      } else {
        print('❌ Notification permission denied');
      }

      return result.isGranted;
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Jadwalkan notifikasi pada waktu tertentu
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // 🌐 Web version
    if (kIsWeb) {
      if (html.Notification.supported &&
          html.Notification.permission == "granted") {
        html.Notification(title, body: body);
      }
      return;
    }

    // Jangan jadwalkan notifikasi di masa lalu
    if (scheduledTime.isBefore(DateTime.now())) {
      print('⚠️ Waktu notifikasi sudah lewat: $scheduledTime');
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_channel',
        'Task Reminder',
        channelDescription: 'Pengingat tugas TaskEase',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      print('✅ Notifikasi dijadwalkan: ID=$id, waktu=$scheduledTime');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  /// Jadwalkan multiple notifikasi untuk satu task (1 hari, 3 hari, 6 jam sebelum deadline)
  static Future<void> scheduleTaskReminders({
    required String taskId,
    required String title,
    required DateTime deadline,
  }) async {
    if (kIsWeb) return;

    final now = DateTime.now();

    // Notifikasi 3 hari sebelum deadline
    final threeDaysBefore = deadline.subtract(const Duration(days: 3));
    if (threeDaysBefore.isAfter(now)) {
      await scheduleNotification(
        id: '${taskId}_3d'.hashCode,
        title: '📅 3 hari lagi!',
        body: 'Tugas "$title" akan jatuh tempo 3 hari lagi',
        scheduledTime: threeDaysBefore,
      );
    }

    // Notifikasi 1 hari sebelum deadline
    final oneDayBefore = deadline.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(now)) {
      await scheduleNotification(
        id: '${taskId}_1d'.hashCode,
        title: '⏰ Besok deadline!',
        body: 'Tugas "$title" akan jatuh tempo besok',
        scheduledTime: oneDayBefore,
      );
    }

    // Notifikasi 6 jam sebelum deadline
    final sixHoursBefore = deadline.subtract(const Duration(hours: 6));
    if (sixHoursBefore.isAfter(now)) {
      await scheduleNotification(
        id: '${taskId}_6h'.hashCode,
        title: '🚨 6 jam lagi!',
        body: 'Tugas "$title" akan jatuh tempo dalam 6 jam',
        scheduledTime: sixHoursBefore,
      );
    }

    print('✅ Semua reminder untuk task "$title" berhasil dijadwalkan');
  }

  /// Batalkan semua notifikasi untuk task tertentu
  static Future<void> cancelTaskReminders(String taskId) async {
    if (kIsWeb) return;

    await _notifications.cancel('${taskId}_3d'.hashCode);
    await _notifications.cancel('${taskId}_1d'.hashCode);
    await _notifications.cancel('${taskId}_6h'.hashCode);
    print('✅ Semua reminder untuk task $taskId dibatalkan');
  }

  /// Batalkan semua notifikasi
  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
    print('✅ Semua notifikasi dibatalkan');
  }
}
