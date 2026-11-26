import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(android: androidSettings, iOS: darwinSettings);

    await _notifications.initialize(settings: settings);
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  }

  Future<void> requestPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleWeeklyNotification() async {
    await _notifications.zonedSchedule(
      id: 1,
      scheduledDate: _nextSundayAt10AM(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_spending',
          'Weekly Spending Reports',
          channelDescription: 'Weekly spending summary notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      title: 'Your Weekly Spending Report',
      body: 'Your spending summary for the previous week is ready.',
    );
  }

  tz.TZDateTime _nextSundayAt10AM() {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);

    while (scheduledDate.weekday != DateTime.sunday || !scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelWeeklyNotification() async {
    await _notifications.cancel(id: 1);
  }

  Future<void> showWeeklyNotification({required String title, required String body}) async {
    await _notifications.show(
      id: 1,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_spending',
          'Weekly Spending Reports',
          channelDescription: 'Weekly spending summary notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> setWeeklyNotificationsEnabled({required bool enabled}) async {
    if (enabled) {
      await scheduleWeeklyNotification();
    } else {
      await cancelWeeklyNotification();
    }
  }
}
