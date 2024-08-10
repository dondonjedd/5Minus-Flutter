import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';

class NotificationService {
  static Future<void> initialise() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

    /// When user open the app through the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});

    /// Update the iOS foreground notification presentation options to allow heads up notifications.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.subscribeToTopic('all');

    if (Platform.isAndroid) {
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      FirebaseMessaging.onMessage.listen((remoteMessage) {
        final notification = remoteMessage.notification;
        final android = remoteMessage.notification?.android;

        if (notification != null && android != null) {
          const channel = AndroidNotificationChannel(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            importance: Importance.high,
          );

          FlutterLocalNotificationsPlugin().initialize(
              const InitializationSettings(
                android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              ),
              onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
              onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse);

          FlutterLocalNotificationsPlugin().show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                icon: '@mipmap/ic_launcher', // Use black and white icon
                color: Colors.transparent,
              ),
            ),
          );
        }
      });
    }
  }

  static Future<String> getToken() async {
    return await FirebaseMessaging.instance.getToken() ?? '';
  }

  const NotificationService._();
}

onDidReceiveNotificationResponse(NotificationResponse response) {}

onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {}
