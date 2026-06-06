import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/notifications/background_notification_dispatcher.dart';
import 'package:flutter_startup_app/core/notifications/notification_service.dart';
import 'package:flutter_startup_app/features/home/presentation/home_screen.dart';
import 'package:flutter_startup_app/features/items/domain/planned_item_filter.dart';
import 'package:flutter_startup_app/features/items/presentation/planned_items_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:media_store_plus/media_store_plus.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MediaStore.ensureInitialized();
  MediaStore.appFolder = 'Ceyiz Takip';

  await NotificationService.initialize();

  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    'today-planned-items-periodic-task',
    todayPlannedItemsTask,
    frequency: const Duration(hours: 24),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  runApp(const ProviderScope(child: StartupApp()));
}

class StartupApp extends StatelessWidget {
  const StartupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Çeyiz Takip',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFD96BA7),
      ),
      home: const HomeScreen(),
      routes: {
        '/today-planned-items': (_) =>
            const PlannedItemsScreen(filter: PlannedItemFilter.today),
      },
    );
  }
}
