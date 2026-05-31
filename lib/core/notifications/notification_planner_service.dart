import 'package:flutter/material.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPlannerService {
  NotificationPlannerService._();

  static const String _lastNotificationDateKey =
      'last_today_planned_items_notification_date';

  static Future<void> checkTodayItems(AppDatabase database) async {
    final items = await database.select(database.items).get();

    final todayItems = _getTodayPlannedItems(items);

    debugPrint('TODAY_PLANNED_ITEMS=${todayItems.length}');

    if (todayItems.isEmpty) {
      return;
    }

    if (await _wasNotificationSentToday()) {
      debugPrint('TODAY_NOTIFICATION_ALREADY_SENT');
      return;
    }

    await NotificationService.showTodayPlannedItemsNotification(
      itemCount: todayItems.length,
    );

    await _markNotificationSentToday();

    debugPrint('TODAY_NOTIFICATION_SENT');
  }

  static List<Item> _getTodayPlannedItems(List<Item> items) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    return items.where((item) {
      if (item.isPurchased) {
        return false;
      }

      if (item.estimatedPurchaseDate == null) {
        return false;
      }

      final targetDate = DateTime.fromMillisecondsSinceEpoch(
        item.estimatedPurchaseDate!,
      );

      final targetDay = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      return targetDay == today;
    }).toList();
  }

  static Future<bool> _wasNotificationSentToday() async {
    final preferences = await SharedPreferences.getInstance();

    final lastDate = preferences.getString(_lastNotificationDateKey);
    final todayKey = _todayKey();

    return lastDate == todayKey;
  }

  static Future<void> _markNotificationSentToday() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_lastNotificationDateKey, _todayKey());
  }

  static String _todayKey() {
    final now = DateTime.now();

    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();

    return '$year-$month-$day';
  }
}
