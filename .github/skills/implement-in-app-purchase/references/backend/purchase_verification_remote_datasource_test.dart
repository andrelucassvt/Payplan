import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../purchase_service.dart';
import 'purchase_verification_remote_datasource.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<Object?> {}

void main() {
  group('PurchaseVerificationRemoteDataSource.parseResult', () {
    test('mapa completo mapeia os campos usados pelo app', () {
      final result = PurchaseVerificationRemoteDataSource.parseResult({
        'isValid': true,
        'state': 'active',
        'platform': 'apple',
        'productId': 'premium_monthly',
        'expiresAt': 1893456000000,
        'willAutoRenew': true,
        'isSandbox': false,
      });

      expect(result.isValid, isTrue);
      expect(result.state, VerificationState.active);
      expect(result.productId, 'premium_monthly');
      expect(
        result.expiresAt,
        DateTime.fromMillisecondsSinceEpoch(1893456000000),
      );
    });

    test('mapeia o estado por nome, não por posição', () {
      final result = PurchaseVerificationRemoteDataSource.parseResult({
        'isValid': true,
        'state': 'gracePeriod',
        'platform': 'google',
      });

      expect(result.state, VerificationState.gracePeriod);
    });

    test('state desconhecido vira unknown', () {
      final result = PurchaseVerificationRemoteDataSource.parseResult({
        'isValid': false,
        'state': 'foo',
        'platform': 'apple',
      });

      expect(result.state, VerificationState.unknown);
    });

    test('expiresAt nulo vira null', () {
      final result = PurchaseVerificationRemoteDataSource.parseResult({
        'isValid': false,
        'state': 'expired',
        'platform': 'apple',
        'expiresAt': null,
      });

      expect(result.expiresAt, isNull);
    });

    test('expiresAt em double também é aceito', () {
      final result = PurchaseVerificationRemoteDataSource.parseResult({
        'isValid': true,
        'state': 'active',
        'platform': 'google',
        'expiresAt': 1893456000000.0,
      });

      expect(
        result.expiresAt,
        DateTime.fromMillisecondsSinceEpoch(1893456000000),
      );
    });

    test('isValid ausente nunca concede acesso por default', () {
      final result = PurchaseVerificationRemoteDataSource.parseResult({
        'state': 'active',
        'platform': 'apple',
      });

      expect(result.isValid, isFalse);
    });
  });

  group('PurchaseVerificationRemoteDataSource.verify', () {
    late MockFirebaseFunctions functions;
    late MockHttpsCallable callable;
    late MockHttpsCallableResult callableResult;
    late PurchaseVerificationRemoteDataSource dataSource;

    const activeResponse = <String, Object?>{
      'isValid': true,
      'state': 'active',
      'platform': 'apple',
      'productId': 'premium_monthly',
      'expiresAt': 1893456000000,
      'willAutoRenew': true,
      'isSandbox': false,
    };

    Map<Object?, Object?> sentParameters() {
      return verify(
            () => callable.call<Object?>(captureAny<Object?>()),
          ).captured.single
          as Map<Object?, Object?>;
    }

    setUp(() {
      functions = MockFirebaseFunctions();
      callable = MockHttpsCallable();
      callableResult = MockHttpsCallableResult();
      dataSource = PurchaseVerificationRemoteDataSource(functions);

      when(() => functions.httpsCallable(any())).thenReturn(callable);
      when(
        () => callable.call<Object?>(any<Object?>()),
      ).thenAnswer((_) async => callableResult);
    });

    test(
      'chama a callable verifyPurchase com platform, type e token',
      () async {
        when(() => callableResult.data).thenReturn(activeResponse);

        final result = await dataSource.verify('token-abc', 'app_store');

        verify(() => functions.httpsCallable('verifyPurchase')).called(1);
        expect(sentParameters(), {
          'platform': 'app_store',
          'type': 'subscription',
          'token': 'token-abc',
        });
        expect(result.isValid, isTrue);
        expect(result.state, VerificationState.active);
        expect(result.productId, 'premium_monthly');
        expect(
          result.expiresAt,
          DateTime.fromMillisecondsSinceEpoch(1893456000000),
        );
      },
    );

    test('envia google_play como platform nas compras do Android', () async {
      when(
        () => callableResult.data,
      ).thenReturn({...activeResponse, 'platform': 'google'});

      await dataSource.verify('token-abc', 'google_play');

      expect(sentParameters()['platform'], 'google_play');
    });

    test('loja desconhecida falha antes de chamar a function', () async {
      await expectLater(
        dataSource.verify('token-abc', 'huawei_appgallery'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('huawei_appgallery'),
          ),
        ),
      );
      verifyNever(() => functions.httpsCallable(any()));
    });

    test('falha da callable é propagada sem mascarar', () async {
      final failure = Exception('rede indisponível');
      when(() => callable.call<Object?>(any<Object?>())).thenThrow(failure);

      await expectLater(
        dataSource.verify('token-abc', 'google_play'),
        throwsA(same(failure)),
      );
    });

    test('resposta sem data falha em vez de conceder acesso', () async {
      when(() => callableResult.data).thenReturn(null);

      await expectLater(
        dataSource.verify('token-abc', 'app_store'),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
