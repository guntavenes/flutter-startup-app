import 'package:flutter/widgets.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/core/notifications/notification_planner_service.dart';
import 'package:flutter_startup_app/core/notifications/notification_service.dart';
import 'package:workmanager/workmanager.dart';

const String todayPlannedItemsTask = 'today_planned_items_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('BACKGROUND_TASK_STARTED');
    print('TASK_NAME=$task');

    WidgetsFlutterBinding.ensureInitialized();

    await NotificationService.initialize(requestPermission: false);

    final database = AppDatabase();

    try {
      if (task == todayPlannedItemsTask) {
        print('CHECKING_TODAY_ITEMS');

        await NotificationPlannerService.checkTodayItems(database);
      }

      print('TASK_COMPLETED');

      return Future.value(true);
    } catch (e) {
      print('BACKGROUND_ERROR=$e');
      return Future.value(false);
    } finally {
      await database.close();
    }
  });
}
