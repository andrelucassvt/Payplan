import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notes_app/src/app_widget.dart';
import 'package:notes_app/src/util/service/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  _setupConfigs();
  runApp(const AppWidget());
}

Future<void> _setupConfigs() async {
  tz.initializeTimeZones();
  await NotificationService().setup();
}
