import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> setup() async {
    const androidInitializationSetting =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInitializationSetting = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
        android: androidInitializationSetting, iOS: iosInitializationSetting);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    tzz.initializeTimeZones();
    const androidNotificationDetail = AndroidNotificationDetails(
      '0', // channel Id
      'general',
    );
    const iosNotificatonDetail = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      iOS: iosNotificatonDetail,
      android: androidNotificationDetail,
    );
    _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(const Duration(days: 2)),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<bool> verificarPermissaoNotificacao() async {
    final result = await Permission.notification.isPermanentlyDenied;
    final resultDanied = await Permission.notification.isDenied;
    debugPrint(result.toString());
    debugPrint(resultDanied.toString());

    if (result == resultDanied) {
      return false;
    } else {
      return true;
    }
  }
}
