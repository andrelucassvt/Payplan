import 'package:flutter/material.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

class AppDialog {
  Future<void> showDialogSimple({
    required String title,
    required String subTitle,
    required BuildContext contextCustom,
  }) {
    return showDialog<void>(
      context: contextCustom,
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
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> showDialogApp({
    required String title,
    required String subTitle,
    required VoidCallback onTapButton1,
    required BuildContext contextCustom,
    VoidCallback? onTapButton2,
    Color? corTextoOnTap,
    Color? corButtonCancelOnTap,
    String? textoButton1,
    String? textoButton2,
    bool isDivida = false,
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: contextCustom,
      barrierDismissible: barrierDismissible,
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
