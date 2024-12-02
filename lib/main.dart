import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notes_app/src/app_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const AppWidget());
}

// Future<void> _setupConfigs() async {
//   await NotificationService().setup();
//   await Future.delayed(const Duration(milliseconds: 100));
//   await AppTrackingTransparency.requestTrackingAuthorization();
// }
