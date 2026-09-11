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
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: _BootstrapApp()));
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late Future<void> _initialization = _initializeServices();

  Future<void> _initializeServices() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // App Check veya bulut senkronizasyonu geçici olarak çalışmasa bile yerel
    // verilerle uygulamanın açılmasına izin ver.
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleDeviceCheckProvider(),
      );

      final user = await AuthService.ensureSignedIn();
      if (user != null) {
        await SharedListRepository().ensureActiveListForUser(user);
      }
    } catch (error, stack) {
      await FirebaseCrashlytics.instance.recordError(error, stack);
    }

    if (Platform.isAndroid) {
      try {
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
      } catch (error, stack) {
        await FirebaseCrashlytics.instance.recordError(error, stack);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const StartupApp();
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Uygulama başlatılamadı. İnternet bağlantını kontrol edip tekrar deneyebilirsin.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _initialization = _initializeServices();
                          });
                        },
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }
}
