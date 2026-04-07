import 'package:flutter/material.dart';

void main() {
  runApp(const StartupApp());
}

class StartupApp extends StatelessWidget {
  const StartupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Startup App',
      home: Scaffold(
        appBar: AppBar(title: const Text('Startup App')),
        body: const Center(child: Text('Project initialized successfully')),
      ),
    );
  }
}
