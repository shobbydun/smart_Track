import 'package:flutter/material.dart';
import 'package:smart_track/components/notification_model.dart';
import 'package:smart_track/database/firestore_services.dart';

class NotificationsPage extends StatefulWidget {
  final FirestoreServices firestoreServices;

  const NotificationsPage({super.key, required this.firestoreServices});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = false;
  String _notificationMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: _clearAllNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _checkLowStockAndNotify,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Check if Stock is Low'),
            ),
          ),
          if (_notificationMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _notificationMessage,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: widget.firestoreServices.getNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No notifications available.'));
                } else {
                  final notifications = snapshot.data!;
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ListTile(
                        title: Text(notification.title),
                        subtitle: Text('${notification.body}\n${notification.timestamp.toDate()}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteNotification(notification.id),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkLowStockAndNotify() async {
    setState(() {
      _isLoading = true;
      _notificationMessage = '';
    });

    try {
      await widget.firestoreServices.checkLowStockAndNotify();
      setState(() {
        _notificationMessage = 'Stock check completed. Notifications have been sent.';
      });
    } catch (e) {
      setState(() {
        _notificationMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await widget.firestoreServices.deleteNotification(id);
      setState(() {
        _notificationMessage = 'Notification deleted.';
      });
    } catch (e) {
      setState(() {
        _notificationMessage = 'An error occurred: $e';
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await widget.firestoreServices.deleteAllNotifications();
      setState(() {
        _notificationMessage = 'All notifications have been deleted.';
      });
    } catch (e) {
      setState(() {
        _notificationMessage = 'An error occurred: $e';
      });
    }
  }
}
