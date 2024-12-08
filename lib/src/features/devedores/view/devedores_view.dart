import 'package:flutter/material.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

class DevedoresView extends StatefulWidget {
  const DevedoresView({super.key});

  @override
  State<DevedoresView> createState() => _DevedoresViewState();
}

class _DevedoresViewState extends State<DevedoresView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(.3),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 20,
          ),
          Center(
            child: Text(
              AppStrings.devedores,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
