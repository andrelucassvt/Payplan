import 'package:flutter/material.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

class PlusPremiumContent extends StatelessWidget {
  const PlusPremiumContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified, color: Colors.amber, size: 80),
          const SizedBox(height: 20),
          Text(
            AppStrings.aproveiteSemAnuncios,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
