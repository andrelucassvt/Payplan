import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_service.dart';

class MockInAppPurchase extends Mock implements InAppPurchase {}

class FakeProductDetails extends Fake implements ProductDetails {
  FakeProductDetails(this.id);

  @override
  final String id;
}

/// `SharedPreferencesAsync` em memória.
class MemoryStorage extends Fake implements SharedPreferencesAsync {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

/// Lojas falsas: cada teste escolhe a plataforma e o que a loja devolve.
class FakeQueries implements StoreQueries {
  FakeQueries({this.usesStoreKit2 = false, this.usesGooglePlay = false});

  @override
  final bool usesStoreKit2;
  @override
  final bool usesGooglePlay;
  List<SK2Transaction> unfinished = [];
  List<SK2Transaction> entitlements = [];
  List<PurchaseDetails> googlePlay = [];

  @override
  Future<List<SK2Transaction>> unfinishedTransactions() async => unfinished;

  @override
  Future<List<SK2Transaction>> currentEntitlements() async => entitlements;

  @override
  Future<List<PurchaseDetails>> googlePlayPurchases() async => googlePlay;
}

final DateTime future = DateTime.now().add(const Duration(days: 30));
final DateTime past = DateTime.now().subtract(const Duration(days: 1));

SK2Transaction appleTransaction({DateTime? expiresAt}) => SK2Transaction(
  id: '11',
  originalId: 'orig-1',
  productId: 'premium_monthly',
  purchaseDate: '0',
  expirationDate: expiresAt == null
      ? null
      : '${expiresAt.millisecondsSinceEpoch}',
  appAccountToken: null,
  jsonRepresentation: jsonEncode({'originalTransactionId': 'orig-1'}),
);

PurchaseDetails applePurchase({
  String productId = 'premium_monthly',
  PurchaseStatus status = PurchaseStatus.purchased,
}) => SK2PurchaseDetails(
  productID: productId,
  purchaseID: '11',
  verificationData: PurchaseVerificationData(
    localVerificationData: jsonEncode({'originalTransactionId': 'orig-1'}),
    serverVerificationData: 'jws',
    source: 'app_store',
  ),
  transactionDate: '0',
  status: status,
);

/// Compra do Google Play ainda não reconhecida (`pendingCompletePurchase`).
PurchaseDetails googlePurchase({String productId = 'premium_monthly'}) =>
    PurchaseDetails(
      purchaseID: 'GPA.1',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '{}',
        serverVerificationData: 'purchase-token',
        source: 'google_play',
      ),
      transactionDate: '0',
      status: PurchaseStatus.purchased,
    )..pendingCompletePurchase = true;

StoreVerification active() => StoreVerification(
  isValid: true,
  state: VerificationState.active,
  productId: 'premium_monthly',
  expiresAt: future,
);

/// Tudo no Service falso roda em microtasks: um ciclo basta para a fila.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late MockInAppPurchase store;
  late StreamController<List<PurchaseDetails>> updates;
  late MemoryStorage storage;
  late FakeQueries queries;
  late List<PurchaseNotice> notices;

  setUpAll(() {
    registerFallbackValue(applePurchase());
    registerFallbackValue(
      PurchaseParam(productDetails: FakeProductDetails('premium_monthly')),
    );
  });

  setUp(() {
    store = MockInAppPurchase();
    updates = StreamController<List<PurchaseDetails>>.broadcast();
    storage = MemoryStorage();
    queries = FakeQueries();
    notices = [];
    when(() => store.purchaseStream).thenAnswer((_) => updates.stream);
    when(() => store.completePurchase(any())).thenAnswer((_) async {});
    when(() => store.restorePurchases()).thenAnswer((_) async {});
    when(
      () => store.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')),
    ).thenAnswer((_) async => true);
  });

  tearDown(() => updates.close());

  PurchaseService build({VerifyToken? verifyToken}) {
    final service = PurchaseService(
      verifyToken: verifyToken,
      store: store,
      storage: storage,
      queries: queries,
    );
    service.events.listen((event) => notices.add(event.notice));
    addTearDown(service.dispose);
    return service;
  }

  Future<void> deliver(
    PurchaseService service,
    PurchaseDetails purchase,
  ) async {
    await service.start();
    updates.add([purchase]);
    await settle();
  }

  group('modo local', () {
    test('iOS concede com o direito atual do StoreKit e finaliza', () async {
      queries = FakeQueries(usesStoreKit2: true)
        ..entitlements = [appleTransaction(expiresAt: future)];
      final service = build();

      await deliver(service, applePurchase());

      expect(notices, [PurchaseNotice.granted]);
      expect(service.hasPremium, isTrue);
      verify(() => store.completePurchase(any())).called(1);
    });

    test('iOS na carência da Apple ainda concede', () async {
      queries = FakeQueries(usesStoreKit2: true)
        ..entitlements = [appleTransaction(expiresAt: past)];
      final service = build();

      await deliver(service, applePurchase());

      expect(notices, [PurchaseNotice.granted]);
      expect(service.hasPremium, isTrue);
    });

    test('iOS fora dos direitos atuais finaliza sem conceder', () async {
      queries = FakeQueries(usesStoreKit2: true);
      final service = build();

      await deliver(service, applePurchase());

      expect(notices, [PurchaseNotice.verificationInvalid]);
      expect(service.hasPremium, isFalse);
      verify(() => store.completePurchase(any())).called(1);
    });

    test('Android concede e reconhece a compra do Play Billing', () async {
      final purchase = googlePurchase();
      queries = FakeQueries(usesGooglePlay: true)..googlePlay = [purchase];
      final service = build();

      await deliver(service, purchase);

      expect(notices, [PurchaseNotice.granted]);
      expect(service.hasPremium, isTrue);
      verify(() => store.completePurchase(purchase)).called(1);
    });
  });

  group('verificação', () {
    test('inválida no Android não reconhece a compra', () async {
      final service = build(
        verifyToken: (_, _) async => const StoreVerification(
          isValid: false,
          state: VerificationState.expired,
        ),
      );

      await deliver(service, googlePurchase());

      expect(notices, [PurchaseNotice.verificationInvalid]);
      verifyNever(() => store.completePurchase(any()));
    });

    test('indisponível não finaliza e a nova tentativa concede', () async {
      var online = false;
      final service = build(
        verifyToken: (_, _) async =>
            online ? active() : throw StateError('offline'),
      );

      await deliver(service, applePurchase());
      expect(notices, [PurchaseNotice.verificationUnavailable]);
      verifyNever(() => store.completePurchase(any()));

      online = true;
      await service.retryUnverified();
      await settle();

      expect(notices.last, PurchaseNotice.granted);
      expect(service.hasPremium, isTrue);
      verify(() => store.completePurchase(any())).called(1);
    });

    test('pendente não concede nem finaliza', () async {
      final service = build(verifyToken: (_, _) async => active());

      await deliver(service, applePurchase(status: PurchaseStatus.pending));

      expect(notices, [PurchaseNotice.pending]);
      verifyNever(() => store.completePurchase(any()));
    });

    test('cancelamento anônimo do Android libera o paywall', () async {
      final service = build();

      await deliver(
        service,
        PurchaseDetails(
          purchaseID: '',
          productID: '',
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'google_play',
          ),
          transactionDate: null,
          status: PurchaseStatus.canceled,
        ),
      );

      expect(notices, [PurchaseNotice.canceled]);
    });

    test('produto de outra feature é ignorado', () async {
      final service = build(verifyToken: (_, _) async => active());

      await deliver(service, applePurchase(productId: 'coins_100'));

      expect(notices, isEmpty);
      verifyNever(() => store.completePurchase(any()));
    });
  });

  group('restauração', () {
    test('vazia ou só com outros produtos avisa que não há nada', () async {
      final service = build();

      await service.restore();
      updates.add([]);
      await settle();
      await service.restore();
      updates.add([
        applePurchase(productId: 'coins_100', status: PurchaseStatus.restored),
      ]);
      await settle();

      expect(notices, [
        PurchaseNotice.nothingToRestore,
        PurchaseNotice.nothingToRestore,
      ]);
    });

    test('falha da loja emite restoreFailed', () async {
      when(
        () => store.restorePurchases(),
      ).thenThrow(PlatformException(code: 'storekit2_restore_failed'));
      final service = build();

      await service.restore();
      await settle();

      expect(notices, [PurchaseNotice.restoreFailed]);
    });
  });

  group('checkPremium', () {
    void saveRecord({DateTime? verifiedAt}) {
      storage.values['iap_subscription_premium_monthly'] = jsonEncode({
        'token': 'orig-1',
        'source': 'app_store',
        'expiresAt': future.toIso8601String(),
        'active': true,
        'verifiedAt': ?verifiedAt?.toIso8601String(),
      });
    }

    test(
      'registro antigo reconsulta a loja e perde o acesso vencido',
      () async {
        saveRecord();
        var calls = 0;
        final service = build(
          verifyToken: (_, _) async {
            calls++;
            return const StoreVerification(
              isValid: false,
              state: VerificationState.expired,
            );
          },
        );

        expect(await service.checkPremium(), isFalse);
        expect(calls, 1);
      },
    );

    test('confirmado há pouco não reconsulta; chamadas juntas dividem a '
        'execução', () async {
      saveRecord(verifiedAt: DateTime.now());
      var calls = 0;
      final service = build(
        verifyToken: (_, _) async {
          calls++;
          return active();
        },
      );

      final results = await Future.wait([
        service.checkPremium(),
        service.checkPremium(),
      ]);

      expect(results, [isTrue, isTrue]);
      expect(calls, 0);
    });

    test('recupera no Android a compra que ficou sem reconhecimento', () async {
      final purchase = googlePurchase();
      queries = FakeQueries(usesGooglePlay: true)..googlePlay = [purchase];
      final service = build();

      expect(await service.checkPremium(), isTrue);
      verify(() => store.completePurchase(purchase)).called(1);
    });
  });

  group('liquidação do StoreKit 2 antes da compra', () {
    test('transação antiga ainda válida concede sem cobrar de novo', () async {
      queries = FakeQueries(usesStoreKit2: true)
        ..unfinished = [appleTransaction(expiresAt: future)]
        ..entitlements = [appleTransaction(expiresAt: future)];
      final service = build();

      await service.buy(FakeProductDetails('premium_monthly'));
      await settle();

      expect(notices, [PurchaseNotice.granted]);
      verify(() => store.completePurchase(any())).called(1);
      verifyNever(
        () => store.buyNonConsumable(
          purchaseParam: any(named: 'purchaseParam'),
        ),
      );
    });

    test('transação vencida é finalizada e a compra abre', () async {
      queries = FakeQueries(usesStoreKit2: true)
        ..unfinished = [appleTransaction(expiresAt: past)];
      final service = build();

      await service.buy(FakeProductDetails('premium_monthly'));
      await settle();

      expect(notices, isEmpty);
      verify(() => store.completePurchase(any())).called(1);
      verify(
        () => store.buyNonConsumable(
          purchaseParam: any(named: 'purchaseParam'),
        ),
      ).called(1);
    });

    test('sem verificação não finaliza nem abre a compra', () async {
      queries = FakeQueries(usesStoreKit2: true)
        ..unfinished = [appleTransaction(expiresAt: future)];
      final service = build(
        verifyToken: (_, _) async => throw StateError('offline'),
      );

      await service.buy(FakeProductDetails('premium_monthly'));
      await settle();

      expect(notices, [PurchaseNotice.verificationUnavailable]);
      verifyNever(() => store.completePurchase(any()));
      verifyNever(
        () => store.buyNonConsumable(
          purchaseParam: any(named: 'purchaseParam'),
        ),
      );
    });
  });
}
