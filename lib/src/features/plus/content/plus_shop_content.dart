import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

class PlusShopContent extends StatelessWidget {
  const PlusShopContent({
    super.key,
    required this.products,
    required this.isProcessing,
    required this.onBuy,
    required this.onRestore,
  });

  final List<ProductDetails> products;
  final bool isProcessing;
  final VoidCallback onBuy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, color: Colors.amber, size: 80),
          const SizedBox(height: 20),
          Text(
            AppStrings.removaTodosAnuncios,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isProcessing ? null : onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      '${AppStrings.removerAnunciosPor} ${products.first.price}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  AppStrings.termoDeUsoEula,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://github.com/andrelucassvt/Payplan/blob/main/README.md',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  AppStrings.termoDePrivacidade,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: onRestore,
            child: Text(
              AppStrings.restaurarCompras,
              style: const TextStyle(
                color: Colors.grey,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
