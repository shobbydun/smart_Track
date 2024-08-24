import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> scheduleNotifications(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  // Initialize time zones
  tz.initializeTimeZones();
  
  // Notification details
  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
    'channel_id', // Channel ID
    'channel_name', // Channel name
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );

  try {
    // Schedule 10 AM notification
    final tenAM = _nextInstanceOf10AM();
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Good Morning!',
      'Success on the day',
      tenAM,
      notificationDetails,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    print('10 AM notification scheduled for: $tenAM');

    // Schedule 10 PM notification
    final tenPM = _nextInstanceOf10PM();
    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Daily Summary',
      'Check the sales and stock summary',
      tenPM,
      notificationDetails,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    print('10 PM notification scheduled for: $tenPM');
  } catch (e) {
    print('Error scheduling notifications: $e');
  }
}

tz.TZDateTime _nextInstanceOf10AM() {
  final now = tz.TZDateTime.now(tz.local);
  final tenAM = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
  if (tenAM.isBefore(now)) {
    return tenAM.add(const Duration(days: 1));
  }
  return tenAM;
}

tz.TZDateTime _nextInstanceOf10PM() {
  final now = tz.TZDateTime.now(tz.local);
  final tenPM = tz.TZDateTime(tz.local, now.year, now.month, now.day, 22);
  if (tenPM.isBefore(now)) {
    return tenPM.add(const Duration(days: 1));
  }
  return tenPM;
}
