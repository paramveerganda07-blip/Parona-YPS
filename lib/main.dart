import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'screens/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: YpsEventApp(),
    ),
  );
}

class YpsEventApp extends StatelessWidget {
  const YpsEventApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YPS Patiala - Events & Sports Day',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: YPSColors.backgroundLight,
        primaryColor: YPSColors.primaryMaroon,
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
          seedColor: YPSColors.primaryMaroon,
          primary: YPSColors.primaryMaroon,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}