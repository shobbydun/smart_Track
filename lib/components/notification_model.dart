import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final Timestamp timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> firestore, String id) {
    return NotificationModel(
      id: id,
      title: firestore['title'] ?? '',
      body: firestore['body'] ?? '',
      timestamp: firestore['timestamp'] ?? Timestamp.now(),
    );
  }
}
