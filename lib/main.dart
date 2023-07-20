import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notes_app/src/app_widget.dart';
import 'package:notes_app/src/util/inject/app_inject.dart';
import 'package:notes_app/src/util/service/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  AppInject.init();
  await NotificationService().setup();
  runApp(const AppWidget());
}
