import 'package:flutter/material.dart';
import 'package:notes_app/src/util/service/navigation_service.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

class AppDialog {
  var currentContext = NavigationService.navigatorKey.currentContext!;
  Future<void> showDialogApp({
    required String title,
    required String subTitle,
    required VoidCallback onTapButton1,
    VoidCallback? onTapButton2,
    BuildContext? contextCustom,
    Color? corTextoOnTap,
    Color? corButtonCancelOnTap,
    String? textoButton1,
    String? textoButton2,
    bool isDivida = false,
  }) {
    return showDialog<void>(
      context: contextCustom ?? currentContext,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(subTitle),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppStrings.cancelar,
                style: TextStyle(
                  color: corButtonCancelOnTap,
                ),
              ),
            ),
            if (isDivida)
              TextButton(
                onPressed: onTapButton2,
                child: Text(
                  textoButton2 ?? AppStrings.salvar,
                  style: TextStyle(
                    color: corTextoOnTap,
                  ),
                ),
              ),
            TextButton(
              onPressed: onTapButton1,
              child: Text(
                textoButton1 ?? AppStrings.salvar,
                style: TextStyle(
                  color: corTextoOnTap,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
