import 'package:flutter/material.dart';
import 'package:flutter_startup_app/features/home/presentation/home_screen.dart';

class StartupApp extends StatelessWidget {
  const StartupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Startup App',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
