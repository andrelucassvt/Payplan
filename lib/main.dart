import 'package:flutter/material.dart';
import 'package:notes_app/src/app_widget.dart';
import 'package:notes_app/src/util/service/ads/ad_service.dart';
import 'package:notes_app/src/util/service/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService().initialize();
  _setupConfigs();
  runApp(const AppWidget());
}

Future<void> _setupConfigs() async {
  tz.initializeTimeZones();
  await NotificationService().setup();
}
