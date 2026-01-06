import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const SkuCheckerApp());
}

class SkuCheckerApp extends StatelessWidget {
  const SkuCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cek Stock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.slate50,
        primaryColor: AppColors.biru,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.biru),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const MainScreen(),
    );
  }
}
