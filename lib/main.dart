import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/app_navigation_service.dart';
import 'services/notification_token_service.dart';
import 'services/report_service.dart';
import 'theme/rainguard_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const RainGuardApp());
  unawaited(NotificationTokenService.initialize());
  ReportService.startPendingDraftRetry();
}

class RainGuardApp extends StatelessWidget {
  const RainGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RainGuard',
      navigatorKey: AppNavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: RainGuardTheme.light(),
      home: const SplashScreen(),
    );
  }
}
