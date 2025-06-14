import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

class PlusView extends StatefulWidget {
  const PlusView({super.key});

  @override
  State<PlusView> createState() => _PlusViewState();
}

class _PlusViewState extends State<PlusView> {
  bool isLoading = true;
  bool isProcessing = false;
  bool isPremium = false;

  // InAppPurchase instance to handle in-app purchases
  final _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  final Set<String> _kIds = {'sem_anuncio'};

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _inAppPurchase.purchaseStream.listen((purchases) {
      if (mounted) {
        for (final purchase in purchases) {
          if (purchase.status == PurchaseStatus.purchased) {
            setState(() {
              isPremium = true;
              isProcessing = false;
              UserController.setUser(UserEntity(isPlus: true));
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Compra realizada com sucesso!')),
            );
            _inAppPurchase.completePurchase(purchase);
          } else if (purchase.status == PurchaseStatus.error) {
            setState(() {
              isProcessing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao processar compra.')),
            );
          } else if (purchase.status == PurchaseStatus.canceled) {
            setState(() {
              isProcessing = false;
            });
          } else if (purchase.status == PurchaseStatus.restored) {
            setState(() {
              isPremium = true;
              isProcessing = false;
              UserController.setUser(UserEntity(isPlus: true));
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Compras restauradas com sucesso!')),
            );
          }
        }
      }
    });
  }

  Future<void> _loadProducts() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return;
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_kIds);
    if (response.productDetails.isNotEmpty) {
      setState(() {
        _products = response.productDetails;
        isLoading = false;
      });
    }
  }

  void _comprarProduto(ProductDetails product) async {
    setState(() {
      isProcessing = true;
    });
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.semAnuncio,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_downward,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: isPremium
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified,
                            color: Colors.amber, size: 80),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.aproveiteSemAnuncios,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.block,
                              color: Colors.amber, size: 80),
                          const SizedBox(height: 20),
                          Text(
                            AppStrings.removaTodosAnuncios,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () {
                                      _comprarProduto(_products.first);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: isProcessing
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      'Remover anúncios por ${_products.first.price}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(
                            height: 50,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final url = Uri.parse(
                                      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/');

                                  await launchUrl(url);
                                },
                                child: const Text(
                                  'Termo de uso (EULA)',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.blue,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final url = Uri.parse(
                                      'https://github.com/andrelucassvt/Payplan/blob/main/README.md');

                                  await launchUrl(url);
                                },
                                child: const Text(
                                  'Termo de privacidade',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.blue,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          InkWell(
                            onTap: () {
                              _inAppPurchase.restorePurchases();
                            },
                            child: Text(
                              'Restaurar compras',
                              style: TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }
}
