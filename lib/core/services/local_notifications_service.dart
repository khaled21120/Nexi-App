import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/app_routers.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await LocalNotificationService.init();
  await LocalNotificationService.showBasicNotification(message);
}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final StreamController<NotificationResponse> streamController =
      StreamController();

  static bool _isInitialized = false;

  static void onTap(NotificationResponse resp) {
    if (resp.payload == null) return;

    final data = jsonDecode(resp.payload!);

    if (data['type'] == 'room_chat') {
      AppRouter.router.pushNamed('home');
    }
  }

  static Future<void> init() async {
    if (_isInitialized) return;

    // Create Android channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_channel', // must match your channel id
      'Chat messages',
      description: 'Channel for chat notifications',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Initialization settings
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      ), // Make sure this exists
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onTap,
      onDidReceiveBackgroundNotificationResponse: onTap,
    );

    _isInitialized = true;

    // Setup foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await showBasicNotification(message);
    });

    // Setup background message handling
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<void> showBasicNotification(RemoteMessage message) async {
    if (!_isInitialized) {
      await init();
    }

    final android = const AndroidNotificationDetails(
      'chat_channel',
      'Chat messages',
      channelDescription: 'Channel for chat notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/launcher_icon',
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: android, iOS: ios);

    final payload = jsonEncode(message.data);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      message.notification?.title ?? "New message",
      message.notification?.body ?? "You have a new message",
      details,
      payload: payload,
    );
  }
}
