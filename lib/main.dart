import 'dart:convert'; // 👈 MUST ADD FOR JSON
import 'package:flutter/material.dart';
import 'package:jobportal/screens/notification_screen.dart';
import 'package:jobportal/screens/job_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 MUST ADD

import 'providers/job_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
);

// 🚀 SENIOR FIX 1: Background Handler now saves data to disk!
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // I have started work on JOB Portal[rahul dabhi]
  // Background mein notification aate hi phone storage mein daal do
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final String? data = prefs.getString('saved_notifications');
  List<dynamic> jsonList = (data != null && data.isNotEmpty) ? jsonDecode(data) : [];

  jsonList.insert(0, {
    'title': message.notification?.title ?? 'New Alert',
    'body': message.notification?.body ?? '',
    'jobId': message.data['job_id']?.toString() ?? '',
    'timestamp': DateTime.now().toIso8601String(),
  });

  await prefs.setString('saved_notifications', jsonEncode(jsonList));
  debugPrint("✅ Background Notification Saved to Disk");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  } catch (e) {
    debugPrint("🔥 Firebase Initialization Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const JobPortalApp(),
    ),
  );
}

class JobPortalApp extends StatefulWidget {
  const JobPortalApp({super.key});
  @override
  State<JobPortalApp> createState() => _JobPortalAppState();
}

// 🚀 SENIOR FIX 2: Added WidgetsBindingObserver to detect app open
class _JobPortalAppState extends State<JobPortalApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observer on
    _setupPushNotifications();
    // _setupInteractedMessage();

    // 🚀 Dhyan do: Yahan se getInitialMessage hata diya hai
    // Hum terminated state splash screen mein handle karenge.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Observer off
    super.dispose();
  }

  // 🚀 Jab user direct app icon click karke kholega, ye trigger hoga
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (navigatorKey.currentContext != null) {
        // Turant disk se naya data fetch karo
        Provider.of<NotificationProvider>(navigatorKey.currentContext!, listen: false).loadNotifications();
      }
    }
  }

  // void _setupInteractedMessage() async {
  //   RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  //   if (initialMessage != null) _handleMessageClick(initialMessage);
  //   FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);
  // }

  void _handleMessageClick(RemoteMessage message) {
    debugPrint("Notification Tapped! Data: ${message.data}");
    String jobId = message.data['job_id']?.toString() ?? "";

    if (message.notification != null) {
      Future.microtask(() {
        if (navigatorKey.currentContext != null) {
          Provider.of<NotificationProvider>(navigatorKey.currentContext!, listen: false).addNotification(
            message.notification!.title ?? 'New Alert',
            message.notification!.body ?? '',
            jobId,
          );
        }
      });
    }

    if (jobId.isNotEmpty) {
      navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => JobDetailScreen(jobId: jobId))
      );
    } else {
      navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const NotificationScreen())
      );
    }
  }

  void _setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null && details.payload!.isNotEmpty) {
          navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => JobDetailScreen(jobId: details.payload!))
          );
        }
      },
    );

    await fcm.requestPermission();
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    String? token = await fcm.getToken();
    if (token != null) {
      _syncTokenWithBackend(token);
    }
    fcm.onTokenRefresh.listen(_syncTokenWithBackend);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      String jobId = message.data['job_id']?.toString() ?? "";
      if (notification != null) {
        if (mounted) {
          Provider.of<NotificationProvider>(context, listen: false).addNotification(
            notification.title ?? 'New Alert',
            notification.body ?? '',
            jobId,
          );
        }

        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id, channel.name,
              channelDescription: channel.description,
              icon: 'ic_notification',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: jobId,
        );
      }
    });
  }

  void _syncTokenWithBackend(String token) async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      await authProvider.syncFCMToken();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'GovJob Portal',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.indigo,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.indigo,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          builder: (context, child) => child ?? const SizedBox.shrink(),
          home: const SplashScreen(),
        );
      },
    );
  }
}