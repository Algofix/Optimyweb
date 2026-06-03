import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class OptimywebApp extends StatelessWidget {
  const OptimywebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Optimyweb',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
