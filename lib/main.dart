import 'dart:io';
import 'package:ceyizim_plus/app.dart';
import 'package:ceyizim_plus/core/notifications/background_notification_dispatcher.dart';
import 'package:ceyizim_plus/core/notifications/notification_service.dart';
import 'package:ceyizim_plus/features/auth/data/auth_service.dart';
import 'package:ceyizim_plus/features/shared_lists/data/shared_list_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleDeviceCheckProvider(),
      );

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      final user = await AuthService.ensureSignedIn();

      if (user != null) {
        final repository = SharedListRepository();
        await repository.ensureActiveListForUser(user);
      }

      if (Platform.isAndroid) {
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
      }

      final analytics = FirebaseAnalytics.instance;

      runApp(const ProviderScope(child: StartupApp()));
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
