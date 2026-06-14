import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/app.dart';
import 'package:flutter_startup_app/core/notifications/background_notification_dispatcher.dart';
import 'package:flutter_startup_app/core/notifications/notification_service.dart';
import 'package:flutter_startup_app/features/auth/data/auth_service.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AuthService.ensureSignedIn();

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

  runApp(const ProviderScope(child: StartupApp()));
}
