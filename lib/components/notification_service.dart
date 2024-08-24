import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_track/components/notification_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final List<NotificationModel> _notifications = [];

  NotificationService(this._flutterLocalNotificationsPlugin);

  Future<void> showNotification(NotificationModel notification) async {
    await _flutterLocalNotificationsPlugin.show(
      notification.id as int,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );

    _notifications.add(notification);
  }

  List<NotificationModel> getNotifications() {
    return _notifications;
  }

  void deleteNotification(int id) {
    _notifications.removeWhere((notification) => notification.id == id);
  }

  void clearAllNotifications() {
    _notifications.clear();
  }
}
