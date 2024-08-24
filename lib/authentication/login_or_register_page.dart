import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_track/authentication/login_page.dart';
import 'package:smart_track/authentication/register_page.dart';

// Assuming you have this object initialized somewhere globally
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  // Initially show login page at start
  bool showLoginPage = true;

  // Toggle between login and register page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        onTap: togglePages,
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
      );
    } else {
      return RegisterPage(
        onTap: togglePages,
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
      );
    }
  }
}
