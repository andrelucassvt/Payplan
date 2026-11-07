import 'package:cloud_functions/cloud_functions.dart';

import '../purchase_service.dart';

/// Verifica assinaturas chamando a callable `verifyPurchase` (Firebase
/// Functions), que consulta a App Store Server API / Google Play Developer
/// API sem expor credenciais no app.
///
/// Entra no `PurchaseService` como `verifyToken: remote.verify` — mesma
/// assinatura de `VerifyToken`. Qualquer exceção (rede, `unavailable`,
/// `internal`, App Check) é propagada sem tratamento: o Service já a trata
/// como verificação indisponível, mantém a transação sem finalizar e tenta
/// de novo depois.
///
/// A instância de [FirebaseFunctions] precisa apontar para a mesma região
/// configurada em `functions/credentials/config.json`
/// (`FirebaseFunctions.instanceFor(region: ...)` quando não for
/// `us-central1`).
class PurchaseVerificationRemoteDataSource {
  const PurchaseVerificationRemoteDataSource(this._functions);

  final FirebaseFunctions _functions;

  /// [source] é `PurchaseVerificationData.source` (`app_store` ou
  /// `google_play`), o mesmo valor que o backend espera em `platform`.
  Future<StoreVerification> verify(String token, String source) async {
    if (source != 'app_store' && source != 'google_play') {
      throw StateError('Loja desconhecida: $source');
    }

    final result = await _functions
        .httpsCallable('verifyPurchase')
        .call<Object?>({
          'platform': source,
          'type': 'subscription',
          'token': token,
        });

    return parseResult(result.data! as Map<Object?, Object?>);
  }

  /// Converte a resposta da callable em [StoreVerification]. Campo ausente
  /// nunca concede acesso: `isValid` cai em `false`, estado desconhecido em
  /// [VerificationState.unknown]. `platform`, `willAutoRenew` e `isSandbox`
  /// também chegam; leia-os aqui se o app precisar.
  static StoreVerification parseResult(Map<Object?, Object?> data) {
    return StoreVerification(
      isValid: data['isValid'] as bool? ?? false,
      state: _stateFromName(data['state'] as String?),
      productId: data['productId'] as String?,
      expiresAt: _dateFromMillis(data['expiresAt']),
    );
  }

  static VerificationState _stateFromName(String? name) {
    return VerificationState.values.firstWhere(
      (value) => value.name == name,
      orElse: () => VerificationState.unknown,
    );
  }

  /// Epoch em ms; o canal pode entregar `int` ou `double`.
  static DateTime? _dateFromMillis(Object? value) {
    if (value is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
}
