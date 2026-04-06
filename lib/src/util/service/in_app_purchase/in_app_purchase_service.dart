import 'package:in_app_purchase/in_app_purchase.dart';

class InAppPurchaseService {
  final _iap = InAppPurchase.instance;

  static const String productId = 'sem_anuncio';
  static const Set<String> _kIds = {productId};

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<List<ProductDetails>> loadProducts() async {
    final available = await _iap.isAvailable();
    if (!available) return [];
    final response = await _iap.queryProductDetails(_kIds);
    return response.productDetails;
  }

  Future<void> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);

  Future<void> restorePurchases() => _iap.restorePurchases();
}
