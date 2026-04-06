import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/service/in_app_purchase/in_app_purchase_service.dart';

part 'plus_state.dart';

class PlusCubit extends Cubit<PlusState> {
  PlusCubit(this._service) : super(const PlusInitial()) {
    _listenToPurchaseStream();
  }

  final InAppPurchaseService _service;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _products = [];

  void _listenToPurchaseStream() {
    _purchaseSubscription = _service.purchaseStream.listen(
      _processPurchaseUpdates,
    );
  }

  Future<void> _processPurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // ignore: unawaited_futures
          UserController.setUser(UserEntity(isPlus: true));
          await _service.completePurchase(purchase);
          emit(PlusPremium(
            isRestored: purchase.status == PurchaseStatus.restored,
          ));
        case PurchaseStatus.error:
          emit(PlusPurchaseError(
            message: purchase.error?.message ?? 'Erro ao processar compra.',
            products: _products,
          ));
        case PurchaseStatus.canceled:
          emit(PlusProductsLoaded(products: _products));
      }
    }
  }

  Future<void> loadProducts() async {
    emit(const PlusLoading());
    try {
      _products = await _service.loadProducts();
      if (_products.isEmpty) {
        emit(const PlusStoreUnavailable());
        return;
      }
      if (UserController.user.value.isPlus) {
        emit(const PlusPremium());
        return;
      }
      emit(PlusProductsLoaded(products: _products));
    } catch (e) {
      emit(PlusPurchaseError(
        message: 'Erro ao carregar produtos: $e',
        products: const [],
      ));
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    emit(PlusProductsLoaded(products: _products, isProcessing: true));
    try {
      await _service.buy(product);
    } catch (e) {
      emit(PlusPurchaseError(
        message: 'Erro ao iniciar compra: $e',
        products: _products,
      ));
    }
  }

  Future<void> restorePurchases() async {
    emit(PlusProductsLoaded(products: _products, isProcessing: true));
    try {
      await _service.restorePurchases();
    } catch (e) {
      emit(PlusPurchaseError(
        message: 'Erro ao restaurar compras: $e',
        products: _products,
      ));
    }
  }

  @override
  Future<void> close() {
    _purchaseSubscription?.cancel();
    return super.close();
  }
}
