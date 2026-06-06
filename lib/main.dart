import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/notifications/background_notification_dispatcher.dart';
import 'package:flutter_startup_app/core/notifications/notification_service.dart';
import 'package:flutter_startup_app/features/home/presentation/home_screen.dart';
import 'package:flutter_startup_app/features/items/domain/planned_item_filter.dart';
import 'package:flutter_startup_app/features/items/presentation/planned_items_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_startup_app/features/auth/data/auth_providers.dart';
import 'package:flutter_startup_app/features/auth/presentation/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

class StartupApp extends ConsumerWidget {
  const StartupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Çeyiz Takip',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFD96BA7),
      ),
      home: authState.when(
        loading: () => const Scaffold(
          backgroundColor: Color(0xFFFFF5FA),
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const LoginScreen(),
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }

          return const HomeScreen();
        },
      ),
      routes: {
        '/today-planned-items': (_) =>
            const PlannedItemsScreen(filter: PlannedItemFilter.today),
      },
    );
  }
}
