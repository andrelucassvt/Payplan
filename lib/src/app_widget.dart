import 'package:flutter/material.dart';
import 'package:notes_app/src/features/home/presenter/home_view.dart';
import 'package:notes_app/src/util/service/navigation_service.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: AppStrings.nameApp,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeView(),
    );
  }
}
