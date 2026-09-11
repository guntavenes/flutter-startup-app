import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/config/app_update_gate.dart';
import 'core/navigation/navigation.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/items/presentation/planned_items_screen.dart';
import 'features/items/domain/planned_item_filter.dart';

class StartupApp extends StatelessWidget {
  const StartupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Çeyiz Takip',
      navigatorKey: navigatorKey,

      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,

      // Türkçe locale
      locale: const Locale('tr', 'TR'),

      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const AppUpdateGate(child: OnboardingGate()),
      routes: {
        '/today-planned-items': (_) =>
            const PlannedItemsScreen(filter: PlannedItemFilter.today),
      },
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: .9,
        maxScaleFactor: 1.6,
        child: child!,
      ),
    );
  }
}
