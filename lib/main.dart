import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_track/authentication/auth_page.dart';
import 'package:smart_track/authentication/login_or_register_page.dart';
import 'package:smart_track/authentication/login_page.dart';
import 'package:smart_track/components/schedule_notifications.dart';
import 'package:smart_track/database/firestore_services.dart';
import 'package:smart_track/firebase_options.dart';
import 'package:smart_track/pages/dashboard_page.dart';
import 'package:smart_track/pages/inventory_management_screen.dart';
import 'package:smart_track/pages/notifications_page.dart';
import 'package:smart_track/pages/product_management_screen.dart';
import 'package:smart_track/pages/sales_management_screen.dart';
import 'package:smart_track/pages/user_profile_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;

// Initialize notification settings
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize timezone
    tz.initializeTimeZones();

    // Configure notification settings
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Initialize local notifications
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize background service
    initializeBackgroundService();

    // Schedule notifications after initialization
    await scheduleNotifications(flutterLocalNotificationsPlugin);

  } catch (e) {
    // Handle initialization errors
    print('Initialization Error: $e');
  }

  // Run the app
  runApp(MyApp());
}

// Define the service entry point
void onServiceStart(ServiceInstance service) {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  flutterLocalNotificationsPlugin.initialize(initializationSettings);

  service.on('checkLowStock').listen((event) async {
    final firestoreServices = FirestoreServices(
      flutterLocalNotificationsPlugin,
      FirebaseAuth.instance.currentUser! as String,
    );
    await firestoreServices.checkLowStockAndNotify();
  });
}

void initializeBackgroundService() {
  FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(autoStart: true),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthPage(flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin),
      routes: {
        '/login_register_page': (context) => const LoginOrRegisterPage(),
        '/dashboard_page': (context) => DashboardPage(firestoreServices: _getFirestoreServices(context)),
        '/inventory_management_page': (context) => InventoryManagementScreen(firestoreServices: _getFirestoreServices(context)),
        '/product_management_page': (context) => ProductManagementScreen(firestoreServices: _getFirestoreServices(context)),
        '/sales_management_page': (context) => SalesManagementScreen(firestoreServices: _getFirestoreServices(context),),
        '/notifications_page': (context) => NotificationsPage(firestoreServices: _getFirestoreServices(context)),
        '/user_profile_page': (context) => UserProfileScreen(firestoreServices: _getFirestoreServices(context)),
        '/login_page': (context) => LoginPage(onTap: () {}, flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,),
      },
    );
  }

  FirestoreServices _getFirestoreServices(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError("User is not authenticated");
    }
    return FirestoreServices(
      flutterLocalNotificationsPlugin,
      user.uid,
    );
  }
}
