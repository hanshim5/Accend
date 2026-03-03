import 'package:flutter/material.dart';
import 'constants.dart';
import 'routes.dart';
import 'theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      initialRoute: AppRoutes.onboardingUserInfo,
      routes: AppRoutes.table,
    );
  }
}