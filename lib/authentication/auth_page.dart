import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_track/authentication/login_or_register_page.dart';
import 'package:smart_track/database/firestore_services.dart';
import 'package:smart_track/pages/dashboard_page.dart';

class AuthPage extends StatelessWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const AuthPage({
    super.key,
    required this.flutterLocalNotificationsPlugin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final User? user = snapshot.data;
            if (user != null) {
              // Pass user.uid to FirestoreServices
              return DashboardPage(
                firestoreServices: FirestoreServices(
                  flutterLocalNotificationsPlugin,
                  user.uid,
                ),
              );
            }
          }

          return LoginOrRegisterPage();
        },
      ),
    );
  }
}
