import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_startup_app/main.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize({bool requestPermission = true}) async {
    final settings = Platform.isIOS
        ? const InitializationSettings(
            iOS: DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true,
            ),
          )
        : const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == 'today_planned_items') {
          Future.delayed(const Duration(milliseconds: 300), () {
            navigatorKey.currentState?.pushNamed('/today-planned-items');
          });
        }
      },
    );

    if (!requestPermission) {
      return;
    }

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static Future<void> showTodayPlannedItemsNotification({
    required int itemCount,
  }) async {
    final details = Platform.isIOS
        ? const NotificationDetails(
            iOS: DarwinNotificationDetails(),
          )
        : const NotificationDetails(
            android: AndroidNotificationDetails(
              'today_planned_items_channel',
              'Bugün Alınacaklar',
              channelDescription: 'Bugün alınması planlanan ürün bildirimleri',
              importance: Importance.max,
              priority: Priority.high,
            ),
          );

    await _plugin.show(
      1001,
      '🛍️ Alınması gereken ürünlerin var',
      '$itemCount ürün bugün için planlanmış görünüyor.',
      details,
      payload: 'today_planned_items',
    );
  }
}