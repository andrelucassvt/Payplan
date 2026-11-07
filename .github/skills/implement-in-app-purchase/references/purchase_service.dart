import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart'
    show InAppPurchaseAndroidPlatformAddition;
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart'
    show InAppPurchaseStoreKitPlatform, SK2PurchaseDetails;
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart'
    show SK2Transaction;
import 'package:shared_preferences/shared_preferences.dart';

/// Troque pelos períodos dos planos cadastrados nas duas lojas.
enum SubscriptionPeriod { monthly, yearly }

/// Avisos do Service para a tela. A compra só termina por eles.
enum PurchaseNotice {
  granted,
  pending,
  canceled,
  purchaseFailed,
  restoreFailed,
  verificationInvalid,
  verificationUnavailable,
  nothingToRestore,
  storeTimeout,
}

class PurchaseEvent {
  const PurchaseEvent(this.notice, {this.productId});

  final PurchaseNotice notice;
  final String? productId;
}

/// Estado da assinatura informado pela loja. Os nomes são o contrato da
/// callable `verifyPurchase` (modo backend); o modo local usa `active`,
/// `pending`, `expired` e `unknown`.
enum VerificationState {
  purchased,
  active,
  canceled,
  gracePeriod,
  billingRetry,
  onHold,
  paused,
  pending,
  expired,
  revoked,
  notFound,
  unknown,
}

/// Resposta da loja sobre uma assinatura, no modo local ou no backend.
class StoreVerification {
  const StoreVerification({
    required this.isValid,
    required this.state,
    this.productId,
    this.expiresAt,
  });

  /// A loja concede acesso agora.
  final bool isValid;
  final VerificationState state;

  /// Produto atual da assinatura; muda em upgrade ou downgrade.
  final String? productId;

  /// Fim do acesso confirmado. Sem ele, nada é concedido.
  final DateTime? expiresAt;
}

/// Confirma a assinatura de `token` na loja `source` (`app_store` ou
/// `google_play`). Sem injeção, o Service usa o modo local; no modo
/// backend, injete `PurchaseVerificationRemoteDataSource.verify`.
typedef VerifyToken =
    Future<StoreVerification> Function(String token, String source);

/// Chamadas nativas de cada loja, isoladas para os testes.
class StoreQueries {
  const StoreQueries();

  bool get usesStoreKit2 =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS &&
      InAppPurchaseStoreKitPlatform.isStoreKit2Enabled;

  bool get usesGooglePlay =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Transações que o StoreKit 2 ainda considera não finalizadas.
  Future<List<SK2Transaction>> unfinishedTransactions() =>
      SK2Transaction.unfinishedTransactions();

  /// Última transação de cada produto com acesso agora. O StoreKit confere
  /// a assinatura da Apple no aparelho e já exclui assinaturas vencidas,
  /// reembolsadas e revogadas.
  Future<List<SK2Transaction>> currentEntitlements() =>
      SK2Transaction.currentEntitlements();

  /// Compras do Google Play com acesso agora (assinatura ativa, cancelada
  /// ainda no período pago ou em carência), inclusive as não reconhecidas.
  Future<List<PurchaseDetails>> googlePlayPurchases() async {
    final response = await InAppPurchase.instance
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
        .queryPastPurchases();
    final error = response.error;
    if (error != null) {
      throw StateError('Google Play: ${error.code} ${error.message}');
    }
    return response.pastPurchases;
  }
}

class PurchaseService {
  PurchaseService({
    VerifyToken? verifyToken,
    InAppPurchase? store,
    SharedPreferencesAsync? storage,
    StoreQueries queries = const StoreQueries(),
  }) : _remoteVerify = verifyToken,
       _store = store ?? InAppPurchase.instance,
       _storage = storage ?? SharedPreferencesAsync(),
       _queries = queries;

  /// Troque pelos IDs cadastrados nas duas lojas. Assinaturas usam
  /// buyNonConsumable no plugin in_app_purchase.
  static const plans = <String, SubscriptionPeriod>{
    'premium_monthly': SubscriptionPeriod.monthly,
    'premium_yearly': SubscriptionPeriod.yearly,
  };

  static const _appStore = 'app_store';
  static const _googlePlay = 'google_play';

  /// Código com que o StoreKit 2 recusa abrir uma compra quando o produto já
  /// tem transação não finalizada.
  static const _duplicateProductCode = 'storekit_duplicate_product_object';

  static const _verifyTimeout = Duration(seconds: 25);

  /// Registro ativo confirmado há menos que isto não reconsulta a loja.
  static const _revalidateInterval = Duration(hours: 12);

  /// Perto do fim do acesso, a loja é sempre reconsultada.
  static const _nearExpiry = Duration(hours: 24);

  /// Validade de uma confirmação local sem data futura: o Play Billing não
  /// informa a expiração e, na carência da Apple, ela já passou.
  static const _deviceConfirmation = Duration(days: 3);

  final VerifyToken? _remoteVerify;
  final InAppPurchase _store;
  final SharedPreferencesAsync _storage;
  final StoreQueries _queries;
  final _events = StreamController<PurchaseEvent>.broadcast();
  final _records = <String, _Entitlement>{};
  final _unverified = <String, PurchaseDetails>{};

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void>? _starting;
  Future<void>? _refreshing;
  Future<void> _queue = Future<void>.value();
  Timer? _retryTimer;
  int _retrySeconds = 30;
  bool _restoring = false;
  bool _disposed = false;

  Stream<PurchaseEvent> get events => _events.stream;

  /// Último resultado verificado neste aparelho; chame checkPremium() antes
  /// de decidir o acesso ao abrir ou retomar o app.
  bool get hasPremium => plans.keys.any(hasAccess);
  SubscriptionPeriod periodOf(String productId) => plans[productId]!;

  bool hasAccess(String productId) {
    final record = _records[productId];
    return record != null &&
        record.active &&
        DateTime.now().isBefore(record.expiresAt);
  }

  /// Revalida com a loja e devolve o acesso atual. Não lança: sem loja ou
  /// rede, vale o acesso já confirmado e ainda dentro de expiresAt.
  Future<bool> checkPremium() async {
    try {
      await refreshAccess();
    } on Object catch (error) {
      debugPrint('IAP: não foi possível atualizar o acesso: $error');
    }
    return hasPremium;
  }

  /// Registre este Service como singleton e chame start() no início do app.
  /// Chamar novamente não cria outro listener.
  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    _subscription = _store.purchaseStream.listen(
      (purchases) => unawaited(
        _serialized(() async {
          await _starting;
          await _handleUpdates(purchases);
        }).catchError((Object error, StackTrace stack) {
          debugPrint('IAP: falha ao processar compras: $error');
          _restoring = false;
          _emit(const PurchaseEvent(PurchaseNotice.purchaseFailed));
        }),
      ),
      onError: (Object error, StackTrace stack) {
        debugPrint('IAP: erro no purchaseStream: $error');
        _restoring = false;
        _emit(const PurchaseEvent(PurchaseNotice.purchaseFailed));
      },
    );
    await _loadRecords();
  }

  Future<List<ProductDetails>> loadProducts() async {
    await start();
    if (!await _store.isAvailable()) {
      throw StateError('Loja indisponível');
    }
    final response = await _store.queryProductDetails(plans.keys.toSet());
    if (response.error != null) {
      throw StateError('Falha ao consultar produtos: ${response.error}');
    }
    if (response.productDetails.isEmpty) {
      throw StateError('Assinaturas não cadastradas: ${response.notFoundIDs}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: IDs não encontrados: ${response.notFoundIDs}');
    }
    // Android pode trazer várias ofertas para o mesmo ID. Escolha a oferta
    // correta para o seu catálogo se houver mais de uma.
    final byId = <String, ProductDetails>{};
    for (final product in response.productDetails) {
      byId.putIfAbsent(product.id, () => product);
    }
    return byId.values.toList(growable: false);
  }

  Future<void> buy(ProductDetails product) async {
    await start();
    if (!plans.containsKey(product.id)) {
      throw ArgumentError.value(product.id, 'product.id', 'ID não configurado');
    }
    // O StoreKit 2 recusa abrir a compra enquanto existir transação não
    // finalizada do mesmo produto, o que acontece com quem já assinou e
    // cancelou. Liquida a fila antes: se a transação antiga ainda vale,
    // concede o acesso em vez de cobrar de novo.
    if (await _settle(product.id) != _UnfinishedQueue.clear) return;
    try {
      await _openCheckout(product);
    } on PlatformException catch (error) {
      if (error.code != _duplicateProductCode) rethrow;
      // Rede de segurança: a transação chegou entre a liquidação e a compra.
      if (await _settle(product.id) != _UnfinishedQueue.clear) return;
      await _openCheckout(product);
    }
  }

  Future<void> _openCheckout(ProductDetails product) async {
    final opened = await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!opened) {
      _emit(
        PurchaseEvent(PurchaseNotice.purchaseFailed, productId: product.id),
      );
    }
    // O resultado chega em purchaseStream, possivelmente em outra sessão.
  }

  Future<_UnfinishedQueue> _settle(String productId) =>
      _serialized(() => _settleUnfinished(productId));

  /// Finaliza as transações não finalizadas de [productId] (só existem no
  /// iOS/StoreKit 2). Uma transação antiga que ainda vale concede o acesso;
  /// expirada é finalizada para liberar a nova compra; sem verificação, nada
  /// é finalizado nem comprado.
  Future<_UnfinishedQueue> _settleUnfinished(String productId) async {
    final List<PurchaseDetails> unfinished;
    try {
      unfinished = await _unfinishedPurchases(productId);
    } on Object catch (error) {
      debugPrint('IAP: não foi possível listar transações pendentes: $error');
      // Sem a lista, tenta abrir a compra: a rede de segurança cobre.
      return _UnfinishedQueue.clear;
    }

    var result = _UnfinishedQueue.clear;
    for (final purchase in unfinished) {
      switch (await _verifyAndGrant(purchase, reportInvalid: false)) {
        case _GrantOutcome.granted:
          return _UnfinishedQueue.granted;
        case _GrantOutcome.invalid:
          // Expirada/cancelada: finalizada, a fila está livre para a compra.
          break;
        case _GrantOutcome.unavailable:
          // Não finalize sem verificar: pode ser um direito de acesso válido.
          result = _UnfinishedQueue.blocked;
      }
    }
    return result;
  }

  /// Transações do [productId] que o StoreKit 2 ainda considera não
  /// finalizadas. Fora do iOS/StoreKit 2 essa fila não existe.
  Future<List<PurchaseDetails>> _unfinishedPurchases(String productId) async {
    if (!_queries.usesStoreKit2) return const [];
    final transactions = await _queries.unfinishedTransactions();
    return [
      for (final transaction in transactions)
        if (transaction.productId == productId)
          SK2PurchaseDetails(
            productID: transaction.productId,
            purchaseID: transaction.id,
            // Mesmo formato do plugin: o JSON e o JWS são os dados de
            // verificação. `purchased` permite o completePurchase.
            verificationData: PurchaseVerificationData(
              localVerificationData: transaction.jsonRepresentation ?? '',
              serverVerificationData: transaction.receiptData ?? '',
              source: _appStore,
            ),
            transactionDate: transaction.purchaseDate,
            status: PurchaseStatus.purchased,
            appAccountToken: transaction.appAccountToken,
            expirationDate: transaction.expirationDate,
            sk2Transaction: transaction,
          ),
    ];
  }

  Future<void> restore() async {
    await start();
    _restoring = true;
    try {
      await _store.restorePurchases();
    } on Object catch (error) {
      debugPrint('IAP: falha ao restaurar: $error');
      _restoring = false;
      _emit(const PurchaseEvent(PurchaseNotice.restoreFailed));
    }
  }

  Future<void> _handleUpdates(List<PurchaseDetails> purchases) async {
    // A restauração chega num lote só, vazio quando não há o que restaurar.
    final isRestoreBatch =
        _restoring &&
        (purchases.isEmpty ||
            purchases.any((p) => p.status == PurchaseStatus.restored));
    var handled = false;
    for (final purchase in purchases) {
      if (await _handlePurchase(purchase)) handled = true;
    }
    if (isRestoreBatch) {
      _restoring = false;
      // Produtos de outras features não contam como restauração.
      if (!handled) {
        _emit(const PurchaseEvent(PurchaseNotice.nothingToRestore));
      }
    }
  }

  /// Processa uma atualização da loja. Devolve `false` quando ela pertence
  /// a outra feature (produto fora de [plans]).
  Future<bool> _handlePurchase(PurchaseDetails purchase) async {
    // No Android, cancelamento ou erro sem compra chega com `productID`
    // vazio. Sem este caso, o paywall ficaria preso no loading.
    final isAnonymousFailure =
        purchase.productID.isEmpty &&
        (purchase.status == PurchaseStatus.canceled ||
            purchase.status == PurchaseStatus.error);
    if (!isAnonymousFailure && !plans.containsKey(purchase.productID)) {
      return false;
    }
    switch (purchase.status) {
      case PurchaseStatus.pending:
        _emit(
          PurchaseEvent(PurchaseNotice.pending, productId: purchase.productID),
        );
      case PurchaseStatus.canceled:
        await _completeIfPending(purchase);
        _emit(
          PurchaseEvent(PurchaseNotice.canceled, productId: purchase.productID),
        );
      case PurchaseStatus.error:
        await _completeIfPending(purchase);
        _emit(
          PurchaseEvent(
            PurchaseNotice.purchaseFailed,
            productId: purchase.productID,
          ),
        );
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _verifyAndGrant(purchase);
    }
    return true;
  }

  /// Verifica a compra e concede, recusa ou guarda para nova tentativa.
  /// Verificações em segundo plano passam `false` nos `report*` para não
  /// interromper a tela; `granted` é sempre emitido.
  Future<_GrantOutcome> _verifyAndGrant(
    PurchaseDetails purchase, {
    bool reportInvalid = true,
    bool reportUnavailable = true,
  }) async {
    final key = _keyOf(purchase);
    final source = purchase.verificationData.source;
    final String token;
    final StoreVerification result;
    try {
      token = _subscriptionToken(purchase);
      result = await _verify(token, source).timeout(_verifyTimeout);
    } on Object catch (error) {
      debugPrint('IAP: verificação indisponível: $error');
      return _keepForRetry(key, purchase, report: reportUnavailable);
    }

    final productId = _resolvedProductId(purchase.productID, result);
    if (productId != null && _grants(result)) {
      try {
        await _save(
          productId,
          _Entitlement(
            token: token,
            source: source,
            expiresAt: result.expiresAt!,
            active: true,
            verifiedAt: DateTime.now(),
          ),
        );
      } on Object catch (error) {
        debugPrint('IAP: não foi possível salvar o acesso: $error');
        return _keepForRetry(key, purchase, report: reportUnavailable);
      }
      _unverified.remove(key);
      _retrySeconds = 30;
      for (final entry in _records.entries.toList()) {
        if (entry.key != productId && entry.value.token == token) {
          await _remove(entry.key);
        }
      }
      await _completeIfPending(purchase);
      _emit(PurchaseEvent(PurchaseNotice.granted, productId: productId));
      return _GrantOutcome.granted;
    }

    if (_isInconclusive(result)) {
      return _keepForRetry(key, purchase, report: reportUnavailable);
    }

    _unverified.remove(key);
    for (final entry in _records.entries.toList()) {
      if (entry.value.token == token) await _remove(entry.key);
    }
    // iOS: finalize, senão a transação bloqueia a recompra do produto.
    // Android: não reconheça. O Google estorna em 3 dias a compra que o app
    // não confirmou, e a recuperação em refreshAccess() tenta até lá.
    if (source != _googlePlay) await _completeIfPending(purchase);
    if (reportInvalid) {
      _emit(
        PurchaseEvent(
          PurchaseNotice.verificationInvalid,
          productId: purchase.productID,
        ),
      );
    }
    return _GrantOutcome.invalid;
  }

  _GrantOutcome _keepForRetry(
    String key,
    PurchaseDetails purchase, {
    required bool report,
  }) {
    _unverified[key] = purchase;
    _scheduleRetry();
    if (report) {
      _emit(
        PurchaseEvent(
          PurchaseNotice.verificationUnavailable,
          productId: purchase.productID,
        ),
      );
    }
    return _GrantOutcome.unavailable;
  }

  static String _keyOf(PurchaseDetails purchase) =>
      purchase.purchaseID ?? purchase.productID;

  /// Concede somente com acesso válido e expiração futura.
  static bool _grants(StoreVerification result) {
    final expiresAt = result.expiresAt;
    return result.isValid &&
        expiresAt != null &&
        DateTime.now().isBefore(expiresAt);
  }

  /// A loja ainda não decidiu: não finalize nem remova; tente de novo.
  static bool _isInconclusive(StoreVerification result) =>
      result.state == VerificationState.pending ||
      result.state == VerificationState.unknown ||
      (result.isValid && result.expiresAt == null);

  String? _resolvedProductId(String requestedId, StoreVerification result) {
    final id = result.productId ?? requestedId;
    return plans.containsKey(id) ? id : null;
  }

  /// Token estável da assinatura na loja que registrou a compra: o
  /// `originalTransactionId` na App Store (o mesmo em renovações, trocas de
  /// plano e restaurações) e o purchaseToken no Google Play. A loja vem de
  /// `source`, não de `Platform`, para o código ser testável em qualquer
  /// máquina.
  static String _subscriptionToken(PurchaseDetails purchase) {
    final data = purchase.verificationData;
    final token = switch (data.source) {
      _appStore => _originalTransactionId(data.localVerificationData),
      _googlePlay => data.serverVerificationData,
      _ => null,
    };
    if (token == null || token.isEmpty) {
      throw StateError('Compra sem token de ${data.source}');
    }
    return token;
  }

  /// No StoreKit 2, `localVerificationData` é o JSON da transação.
  static String? _originalTransactionId(String json) {
    final data = jsonDecode(json);
    return data is Map ? data['originalTransactionId']?.toString() : null;
  }

  Future<StoreVerification> _verify(String token, String source) =>
      (_remoteVerify ?? _verifyOnDevice)(token, source);

  /// Modo local: a loja instalada no aparelho confirma o acesso, sem
  /// credenciais nem servidor.
  Future<StoreVerification> _verifyOnDevice(
    String token,
    String source,
  ) async {
    switch (source) {
      case _appStore:
        return _appStoreEntitlement(token);
      case _googlePlay:
        return _googlePlayEntitlement(token);
    }
    throw StateError('Loja desconhecida: $source');
  }

  Future<StoreVerification> _appStoreEntitlement(
    String originalTransactionId,
  ) async {
    for (final transaction in await _queries.currentEntitlements()) {
      if (transaction.originalId != originalTransactionId) continue;
      // Um grupo de assinaturas tem um só direito atual. Depois de upgrade
      // ou downgrade, é o produto novo, com o mesmo originalTransactionId.
      return StoreVerification(
        isValid: true,
        state: VerificationState.active,
        productId: transaction.productId,
        expiresAt: _deviceExpiry(_dateFromMillis(transaction.expirationDate)),
      );
    }
    // Fora dos direitos atuais: vencida, reembolsada ou revogada.
    return const StoreVerification(
      isValid: false,
      state: VerificationState.expired,
    );
  }

  Future<StoreVerification> _googlePlayEntitlement(
    String purchaseToken,
  ) async {
    for (final purchase in await _queries.googlePlayPurchases()) {
      if (purchase.verificationData.serverVerificationData != purchaseToken) {
        continue;
      }
      if (purchase.status != PurchaseStatus.purchased) {
        return StoreVerification(
          isValid: false,
          state: purchase.status == PurchaseStatus.pending
              ? VerificationState.pending
              : VerificationState.unknown,
          productId: purchase.productID,
        );
      }
      // O Play Billing não informa a expiração no aparelho.
      return StoreVerification(
        isValid: true,
        state: VerificationState.active,
        productId: purchase.productID,
        expiresAt: _deviceExpiry(null),
      );
    }
    // O Play Billing só devolve compras que ainda dão acesso.
    return const StoreVerification(
      isValid: false,
      state: VerificationState.expired,
    );
  }

  /// Expiração da loja quando ainda está no futuro; senão, a confirmação
  /// local vale por [_deviceConfirmation].
  static DateTime _deviceExpiry(DateTime? storeExpiry) {
    final now = DateTime.now();
    if (storeExpiry != null && storeExpiry.isAfter(now)) return storeExpiry;
    return now.add(_deviceConfirmation);
  }

  static DateTime? _dateFromMillis(String? millis) {
    final value = millis == null ? null : int.tryParse(millis);
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
  }

  /// Revalida renovação, expiração e reembolso e recupera compras pagas que
  /// ficaram sem confirmação. Chamadas simultâneas compartilham a execução.
  Future<void> refreshAccess() async {
    await start();
    await (_refreshing ??= _serialized(
      _refresh,
    ).whenComplete(() => _refreshing = null));
  }

  Future<void> _refresh() async {
    await _revalidateRecords();
    await _recoverGooglePlayPurchases();
    await _retryUnverifiedNow();
  }

  Future<void> _revalidateRecords() async {
    for (final entry in _records.entries.toList()) {
      final record = entry.value;
      if (!_needsRevalidation(record)) continue;
      try {
        final result = await _verify(
          record.token,
          record.source,
        ).timeout(_verifyTimeout);
        final id = _resolvedProductId(entry.key, result);
        if (id != null && _grants(result)) {
          await _save(
            id,
            _Entitlement(
              token: record.token,
              source: record.source,
              expiresAt: result.expiresAt!,
              active: true,
              verifiedAt: DateTime.now(),
            ),
          );
          if (id != entry.key) await _remove(entry.key);
        } else if (result.state == VerificationState.revoked ||
            result.state == VerificationState.notFound ||
            id == null) {
          await _remove(entry.key);
        } else if (!_isInconclusive(result)) {
          await _save(
            entry.key,
            _Entitlement(
              token: record.token,
              source: record.source,
              expiresAt: result.expiresAt ?? record.expiresAt,
              active: false,
              verifiedAt: DateTime.now(),
            ),
          );
        }
      } on Object catch (error) {
        // Sem loja ou rede, vale o acesso já confirmado até expiresAt.
        debugPrint('IAP: não foi possível revalidar ${entry.key}: $error');
      }
    }
  }

  /// Confirmado há pouco e longe do fim dispensa a loja. Inativo também
  /// espera o intervalo: a loja pode reativá-lo (fim da retenção no Google).
  static bool _needsRevalidation(_Entitlement record) {
    final verifiedAt = record.verifiedAt;
    if (verifiedAt == null) return true;
    final now = DateTime.now();
    return now.difference(verifiedAt) >= _revalidateInterval ||
        (record.active && record.expiresAt.difference(now) <= _nearExpiry);
  }

  /// O Google Play não reentrega a compra que ficou sem completePurchase
  /// (app fechado durante a verificação, pendência paga depois) e a estorna
  /// em 3 dias. O iOS reentrega as não finalizadas no purchaseStream.
  Future<void> _recoverGooglePlayPurchases() async {
    if (!_queries.usesGooglePlay) return;
    final List<PurchaseDetails> purchases;
    try {
      purchases = await _queries.googlePlayPurchases();
    } on Object catch (error) {
      debugPrint('IAP: não foi possível consultar o Google Play: $error');
      return;
    }
    for (final purchase in purchases) {
      if (!plans.containsKey(purchase.productID) ||
          purchase.status != PurchaseStatus.purchased ||
          !purchase.pendingCompletePurchase ||
          _unverified.containsKey(_keyOf(purchase))) {
        continue;
      }
      await _verifyAndGrant(
        purchase,
        reportInvalid: false,
        reportUnavailable: false,
      );
    }
  }

  /// Nova tentativa das compras pagas que ficaram sem verificação.
  Future<void> retryUnverified() => _serialized(_retryUnverifiedNow);

  Future<void> _retryUnverifiedNow() async {
    if (_disposed) return;
    for (final purchase in _unverified.values.toList()) {
      await _verifyAndGrant(
        purchase,
        reportInvalid: false,
        reportUnavailable: false,
      );
    }
  }

  void _scheduleRetry() {
    if (_retryTimer != null || _disposed) return;
    _retryTimer = Timer(Duration(seconds: _retrySeconds), () {
      _retryTimer = null;
      _retrySeconds = (_retrySeconds * 2).clamp(30, 600);
      unawaited(
        retryUnverified().catchError((Object error, StackTrace stack) {
          debugPrint('IAP: falha na nova tentativa: $error');
        }),
      );
    });
  }

  Future<void> _completeIfPending(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _store.completePurchase(purchase);
    } on Object catch (error) {
      // A loja reentrega a transação. O registro de acesso é idempotente.
      debugPrint('IAP: falha ao finalizar transação: $error');
    }
  }

  /// Roda [task] depois das anteriores: compras, verificações e cache nunca
  /// correm em paralelo. O erro volta para quem chamou e não trava a fila.
  /// Não chame `_serialized` de dentro de uma tarefa da fila.
  Future<T> _serialized<T>(Future<T> Function() task) {
    final result = _queue.then((_) => task());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static String _key(String id) => 'iap_subscription_$id';

  Future<void> _loadRecords() async {
    for (final id in plans.keys) {
      final raw = await _storage.getString(_key(id));
      if (raw == null) continue;
      try {
        _records[id] = _Entitlement.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } on Object catch (_) {
        await _storage.remove(_key(id));
      }
    }
  }

  Future<void> _save(String id, _Entitlement record) async {
    await _storage.setString(_key(id), jsonEncode(record.toJson()));
    _records[id] = record;
  }

  Future<void> _remove(String id) async {
    await _storage.remove(_key(id));
    _records.remove(id);
  }

  void _emit(PurchaseEvent event) {
    if (!_disposed) _events.add(event);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _retryTimer?.cancel();
    await _subscription?.cancel();
    await _queue;
    await _events.close();
  }
}

class _Entitlement {
  const _Entitlement({
    required this.token,
    required this.source,
    required this.expiresAt,
    required this.active,
    this.verifiedAt,
  });

  factory _Entitlement.fromJson(Map<String, dynamic> json) => _Entitlement(
    token: json['token'] as String,
    source: json['source'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    active: json['active'] as bool,
    verifiedAt: switch (json['verifiedAt']) {
      final String value => DateTime.tryParse(value),
      _ => null,
    },
  );

  final String token;
  final String source;
  final DateTime expiresAt;
  final bool active;

  /// Última confirmação da loja. `null` em registros de versões antigas,
  /// revalidados na primeira chance.
  final DateTime? verifiedAt;

  Map<String, Object> toJson() => {
    'token': token,
    'source': source,
    'expiresAt': expiresAt.toIso8601String(),
    'active': active,
    'verifiedAt': ?verifiedAt?.toIso8601String(),
  };
}

/// Desfecho da verificação de uma compra.
enum _GrantOutcome { granted, invalid, unavailable }

/// Situação da fila de transações não finalizadas do StoreKit 2.
enum _UnfinishedQueue {
  /// Nada bloqueia: pode abrir a compra.
  clear,

  /// Uma transação antiga ainda vale: acesso concedido, não cobre de novo.
  granted,

  /// Não deu para verificar: nada foi finalizado nem comprado.
  blocked,
}
