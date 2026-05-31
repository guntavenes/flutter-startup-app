import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_startup_app/main.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

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

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> showTodayPlannedItemsNotification({
    required int itemCount,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'today_planned_items_channel',
      'Bugün Alınacaklar',
      channelDescription: 'Bugün alınması planlanan ürün bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      1001,
      '🛍️ Alınması gereken ürünlerin var',
      '$itemCount ürün bugün için planlanmış görünüyor.',
      details,
      payload: 'today_planned_items',
    );
  }
}
