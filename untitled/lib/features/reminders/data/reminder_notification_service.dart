import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../domain/care_reminder.dart';

final reminderNotificationService = ReminderNotificationService(
  FlutterLocalNotificationsPlugin(),
);

class ReminderNotificationService {
  ReminderNotificationService(this._notifications);

  final FlutterLocalNotificationsPlugin _notifications;

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const _androidDetails = AndroidNotificationDetails(
    'audible_care_reminders',
    'Audible care reminders',
    channelDescription: 'Daily feeding and sleep reminders with sound',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.alarm,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    if (!isSupported) return;
    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimezone));

    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/notification_icon'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notificationsAllowed =
        await android?.requestNotificationsPermission() ?? true;
    final exactAlarmsAllowed =
        await android?.requestExactAlarmsPermission() ?? true;
    final apple = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final appleAllowed = await apple?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
    return notificationsAllowed && exactAlarmsAllowed && appleAllowed;
  }

  Future<void> schedule(CareReminder reminder) async {
    if (!isSupported) return;
    final now = timezone.TZDateTime.now(timezone.local);
    var next = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    await _notifications.zonedSchedule(
      reminder.id,
      '${reminder.type.label} time',
      reminder.type.notificationBody,
      next,
      const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(
          presentSound: true,
          sound: 'default',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: reminder.type.name,
    );
  }

  Future<void> cancel(int id) async {
    if (isSupported) await _notifications.cancel(id);
  }
}
