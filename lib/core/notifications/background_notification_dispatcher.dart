import 'package:ceyizim_plus/core/database/app_database.dart';
import 'package:ceyizim_plus/core/notifications/notification_planner_service.dart';
import 'package:ceyizim_plus/core/notifications/notification_service.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

const String todayPlannedItemsTask = 'today_planned_items_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    await NotificationService.initialize(requestPermission: false);

    final database = AppDatabase();

    try {
      if (task == todayPlannedItemsTask) {
        await NotificationPlannerService.checkTodayItems(database);
      }

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    } finally {
      await database.close();
    }
  });
}
