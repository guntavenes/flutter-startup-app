import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

class StartupApp extends StatelessWidget {
  const StartupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Çeyiz Takip',

      theme: AppTheme.lightTheme,

      // Türkçe locale
      locale: const Locale('tr', 'TR'),

      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const HomeScreen(),
    );
  }
}
