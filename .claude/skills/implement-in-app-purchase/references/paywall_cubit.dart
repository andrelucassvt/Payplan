import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'purchase_service.dart';

/// Estado da tela no mesmo arquivo do Cubit.
class PaywallState {
  const PaywallState({
    this.products = const [],
    this.loading = false,
    this.busy = false,
    this.loadFailed = false,
    this.notice,
    this.grantedProductId,
  });

  final List<ProductDetails> products;
  final bool loading;
  final bool busy;
  final bool loadFailed;
  final PurchaseNotice? notice;
  final String? grantedProductId;
}

class PaywallCubit extends Cubit<PaywallState> {
  PaywallCubit(this._service) : super(const PaywallState()) {
    _subscription = _service.events.listen(_onEvent);
  }

  final PurchaseService _service;
  late final StreamSubscription<PurchaseEvent> _subscription;
  Timer? _watchdog;

  Future<void> load() async {
    emit(PaywallState(products: state.products, loading: true));
    try {
      final products = await _service.loadProducts();
      if (!isClosed) emit(PaywallState(products: products));
    } on Object catch (_) {
      if (!isClosed) {
        emit(PaywallState(products: state.products, loadFailed: true));
      }
    }
  }

  Future<void> buy(ProductDetails product) async {
    if (state.busy || isClosed) return;
    _begin(const Duration(minutes: 2));
    try {
      await _service.buy(product);
      // A compra não terminou aqui. O resultado vem do Service.
    } on Object catch (_) {
      _finish(PurchaseNotice.purchaseFailed);
    }
  }

  Future<void> restore() async {
    if (state.busy || isClosed) return;
    _begin(const Duration(seconds: 45));
    try {
      await _service.restore();
      // A restauração também termina pelo stream, inclusive quando é vazia.
    } on Object catch (_) {
      _finish(PurchaseNotice.restoreFailed);
    }
  }

  void _begin(Duration timeout) {
    _watchdog?.cancel();
    emit(PaywallState(products: state.products, busy: true));
    _watchdog = Timer(timeout, () => _finish(PurchaseNotice.storeTimeout));
  }

  void _onEvent(PurchaseEvent event) {
    // Depois de conceder, a tela já está navegando: ignore o resto.
    if (isClosed || state.grantedProductId != null) return;
    if (event.notice == PurchaseNotice.granted) {
      // Vale mesmo sem ação em curso: pendência aprovada ou nova tentativa.
      _watchdog?.cancel();
      emit(
        PaywallState(
          products: state.products,
          grantedProductId: event.productId,
        ),
      );
      return;
    }
    // Avisos de verificações em segundo plano não interrompem a tela parada.
    if (state.busy) _finish(event.notice);
  }

  void _finish(PurchaseNotice notice) {
    if (isClosed || state.grantedProductId != null) return;
    _watchdog?.cancel();
    emit(
      PaywallState(
        products: state.products,
        notice: notice == PurchaseNotice.canceled ? null : notice,
      ),
    );
  }

  @override
  Future<void> close() async {
    _watchdog?.cancel();
    await _subscription.cancel();
    return super.close();
  }
}
