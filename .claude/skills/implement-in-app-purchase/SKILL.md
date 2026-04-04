---
name: implement-in-app-purchase
description: Implements In-App Purchase (consumable, non-consumable, or subscription) following the project architecture. Asks whether there is a backend server, then generates the complete implementation: InAppPurchaseService, Cubit, State, View, DI registration, and purchase verification flow (local storage via StorageService OR backend endpoint call). Use whenever adding purchases, subscriptions, paywall, or premium features to the app, integrating App Store or Google Play billing, verifying receipts, or restoring purchases. Activate even when the user says 'make the app paid', 'add a paywall', 'implement premium', 'add a subscription plan', 'unlock premium features', 'add a pro version', or 'monetize the app' without explicitly mentioning InAppPurchase, StoreKit, or Google Play Billing.
---

# Implement In-App Purchase — Flutter

Implementa o fluxo completo de In-App Purchase seguindo a arquitetura do projeto.

## Leitura Rápida

- **Primeiro passo obrigatório**: faça TODAS as perguntas ao usuário (Passo 1) antes de gerar qualquer código.
- **Modo sem back-end**: `InAppPurchaseService` + `StorageService` — sem Repository ou DataSource.
- **Modo com back-end**: adiciona Entity + Repository Interface + Model + DataSource + RepositoryImpl.
- **Verificação**: `completePurchase()` NUNCA é chamado antes da verificação — local ou server-side.
- **Stream**: o resultado da compra SEMPRE vem pelo `purchaseStream` — nunca emita `PurchaseSuccess` direto no `buyProduct()`.
- **Cubit**: cancele `_purchaseSubscription` no `close()` — nunca deixe o stream vazar.
- **Apple Guideline 3.1.2(c)**: telas de paywall com assinatura DEVEM exibir links de Termos de Uso e Política de Privacidade.
- **Segurança**: nunca confie apenas na validação client-side para desbloquear conteúdo premium.

---

## Passo 1 — Perguntas obrigatórias ao usuário

Antes de gerar qualquer código, faça TODAS as perguntas abaixo em uma única mensagem usando o `vscode_askQuestions` tool (ou liste claramente e aguarde resposta):

```
1. O app tem back-end próprio?
   - SIM → o back-end valida e registra as compras
   - NÃO → verificação ocorre 100% localmente no dispositivo

2. Quais tipos de produto você precisa implementar?
   - [ ] Consumível (ex: pacotes de créditos, tokens)
   - [ ] Assinatura (ex: plano mensal/anual)
   - [ ] Não-consumível permanente (ex: remover anúncios)

3. Quais são os IDs dos produtos cadastrados nas lojas?
   (App Store Connect e Google Play Console)
   Ex: "basic_1", "pro_pack", "premium_monthly"

4. Qual é o nome da feature/tela onde ficará a lógica de compra?
   Ex: "purchase", "paywall", "subscription"
```

Guarde as respostas para guiar toda a implementação.

---

## Passo 2 — Determinar a arquitetura de verificação

Com base na resposta sobre back-end, siga um dos dois caminhos:

### 🅰️ SEM back-end (verificação local)

Arquitetura:
```
View → Cubit → InAppPurchaseService → App Store / Google Play
                      ↑                        ↓
               purchaseStream          PurchaseDetails
                      ↓
       verifyPurchase / verifySubscription (VerifyLocalPurchase)
                      ↓
       StorageService.setString('purchase_<productId>', verificationData)
```

No `InAppPurchaseService`, após verificação bem-sucedida:
- Salve `purchase.verificationData.localVerificationData` via `StorageService`
- Salve também `purchase.verificationData.source` para identificar a plataforma
- Use chaves consistentes: `'purchase_receipt_<productId>'`

Exemplo no service:
```dart
Future<bool> verifyPurchase(
  PurchaseDetails purchase,
  StorageService storage,
) async {
  final token = getOneTimePurchaseToken(purchase);
  final isValid = await VerifyLocalPurchase().verifyPurchase(token);
  if (isValid) {
    await storage.setString(
      'purchase_receipt_${purchase.productID}',
      purchase.verificationData.localVerificationData,
    );
    await storage.setString(
      'purchase_source_${purchase.productID}',
      purchase.verificationData.source,
    );
    await _iap.completePurchase(purchase);
  }
  return isValid;
}

Future<bool> verifySubscription(
  PurchaseDetails purchase,
  StorageService storage,
) async {
  final token = getSubscriptionToken(purchase);
  final isValid = await VerifyLocalPurchase().verifySubscription(token);
  if (isValid) {
    await storage.setString(
      'purchase_receipt_${purchase.productID}',
      purchase.verificationData.localVerificationData,
    );
    await storage.setString(
      'purchase_source_${purchase.productID}',
      purchase.verificationData.source,
    );
    await _iap.completePurchase(purchase);
  }
  return isValid;
}
```

**Dados salvos no `StorageService`:**

| Chave | Valor | Descrição |
|---|---|---|
| `purchase_receipt_<productId>` | `localVerificationData` | Receipt iOS (base64) ou Purchase Token Android |
| `purchase_source_<productId>` | `app_store` / `google_play` | Plataforma de origem |

**Aviso ao usuário:** Informe que os dados de verificação ficam somente no dispositivo — se o usuário reinstalar o app, as compras não-consumíveis/assinaturas precisarão ser restauradas via `restorePurchases()`.

---

### 🅱️ COM back-end (envio ao servidor)

Arquitetura:
```
View → Cubit → InAppPurchaseService → App Store / Google Play
                      ↑                        ↓
               purchaseStream          PurchaseDetails
                      ↓
             PurchaseRepository (interface no domain)
                      ↓
          PurchaseRepositoryImpl (data layer)
                      ↓
          PurchaseRemoteDataSource → POST /purchases/verify
```

**Dado enviado ao back-end:**
```dart
{
  "product_id": purchase.productID,
  "verification_data": purchase.verificationData.serverVerificationData,
  "source": purchase.verificationData.source,           // "app_store" | "google_play"
  "local_verification_data": purchase.verificationData.localVerificationData,
}
```

**Estrutura de arquivos adicionais (apenas no modo com back-end):**
```
domain/
  entities/purchase_entity.dart
  interfaces/purchase_repository.dart

data/
  models/purchase_model.dart
  datasources/purchase_remote_datasource.dart
  repositories/purchase_repository_impl.dart
```

**Interface do Repository:**
```dart
abstract class PurchaseRepository {
  /// Envia dados de verificação ao back-end e retorna se a compra é válida
  Future<Result<bool>> verifyPurchaseOnServer({
    required String productId,
    required String serverVerificationData,
    required String localVerificationData,
    required String source,
  });
}
```

**No Cubit (modo back-end):**
- Receba `InAppPurchaseService` E `PurchaseRepository`
- No `_processPurchaseUpdates`, após receber `PurchaseStatus.purchased`:
  1. Chame `_purchaseRepository.verifyPurchaseOnServer(...)` com os dados de verificação
  2. Use `result.when(ok: ..., error: ...)` para emitir o estado final
  3. Se validado, chame `_purchaseService.completePurchase(purchase)` manualmente

```dart
// Cubit com back-end — trecho do _processPurchaseUpdates
if (purchase.status == PurchaseStatus.purchased ||
    purchase.status == PurchaseStatus.restored) {
  try {
    final result = await _purchaseRepository.verifyPurchaseOnServer(
      productId: purchase.productID,
      serverVerificationData: purchase.verificationData.serverVerificationData,
      localVerificationData: purchase.verificationData.localVerificationData,
      source: purchase.verificationData.source,
    );

    result.when(
      ok: (isValid) async {
        if (isValid) {
          await _purchaseService.completePurchase(purchase);
        }
        emit(PurchaseSuccess(productId: purchase.productID, isValid: isValid));
      },
      error: (e) => emit(PurchaseError('Verificação no servidor falhou: $e')),
    );
  } catch (e) {
    emit(PurchaseError('Erro inesperado: $e'));
  }
}
```

---

## Passo 3 — Arquivos a criar (mínimo obrigatório)

### Para AMBOS os modos:

```
✅ lib/common/services/in_app_purchase/in_app_purchase_service.dart
✅ lib/presentation/<feature>/view_model/<feature>_cubit.dart
✅ lib/presentation/<feature>/view_model/<feature>_state.dart
✅ lib/presentation/<feature>/view/<feature>_view.dart  ← incluir links de Termos de Uso e Privacidade
✅ Registrar InAppPurchaseService (LazySingleton) e Cubit (Factory) em app_injector.dart
✅ Adicionar rota em app_routes.dart e app_router.dart
✅ Inicializar VerifyLocalPurchase em app_initializer.dart
✅ Adicionar strings premiumTermsOfUse e premiumPrivacyPolicy nos arquivos ARB
```

> ⚠️ **Apple Guideline 3.1.2(c) — obrigatório para assinaturas:** A View de paywall DEVE exibir links funcionais para **Termos de Uso (EULA)** e **Política de Privacidade**. Use `url_launcher` com `LaunchMode.externalApplication`. Exemplo:
>
> ```dart
> import 'package:url_launcher/url_launcher.dart';
> 
> Row(
>   mainAxisAlignment: MainAxisAlignment.center,
>   children: [
>     TextButton(
>       onPressed: () => launchUrl(
>         Uri.parse('https://sua-url/termos'),
>         mode: LaunchMode.externalApplication,
>       ),
>       style: TextButton.styleFrom(
>         padding: const EdgeInsets.symmetric(horizontal: 8),
>         textStyle: theme.textTheme.bodySmall,
>       ),
>       child: Text(l10n.premiumTermsOfUse),
>     ),
>     Text('·', style: theme.textTheme.bodySmall?.copyWith(
>       color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
>     )),
>     TextButton(
>       onPressed: () => launchUrl(
>         Uri.parse('https://sua-url/privacidade'),
>         mode: LaunchMode.externalApplication,
>       ),
>       style: TextButton.styleFrom(
>         padding: const EdgeInsets.symmetric(horizontal: 8),
>         textStyle: theme.textTheme.bodySmall,
>       ),
>       child: Text(l10n.premiumPrivacyPolicy),
>     ),
>   ],
> ),
> ```

### Apenas no modo SEM back-end:
```
✅ Injetar StorageService no InAppPurchaseService (via construtor)
✅ Salvar dados de verificação com StorageService após compra validada
```

### Apenas no modo COM back-end:
```
✅ lib/domain/entities/purchase_entity.dart
✅ lib/domain/interfaces/purchase_repository.dart
✅ lib/data/models/purchase_model.dart
✅ lib/data/datasources/purchase_remote_datasource.dart
✅ lib/data/repositories/purchase_repository_impl.dart
✅ Registrar DataSource e Repository em app_injector.dart
✅ Injetar PurchaseRepository no Cubit junto com InAppPurchaseService
```

---

## Passo 4 — Checklist de implementação

Após gerar o código, valide cada item:

### Service
- [ ] IDs de produtos declarados como constantes `static const`
- [ ] `_productIds` (consumíveis) e `_subscriptionIds` separados em Sets
- [ ] `purchaseStream` exposto para o Cubit
- [ ] `isSubscriptionProduct(productId)` implementado
- [ ] `completePurchase()` chamado apenas após validação bem-sucedida
- [ ] **Sem back-end**: `StorageService` injetado via construtor; dados salvos após verificação
- [ ] **Com back-end**: não salva localmente; delega ao Repository

### Cubit
- [ ] `_listenToPurchaseStream()` chamado no construtor
- [ ] `_purchaseSubscription` cancelado no `close()`
- [ ] `PurchaseStatus.pending` ignorado (apenas `continue`)
- [ ] `PurchaseStatus.error` → emite `PurchaseError`
- [ ] `PurchaseStatus.purchased` e `restored` → verificam e emitem `PurchaseSuccess`
- [ ] `buyProduct()` e `buySubscription()` **não** emitem `PurchaseSuccess` diretamente
- [ ] Todos os métodos assíncronos emitem `PurchaseLoading` primeiro

### State (sealed class)
- [ ] `@immutable` em todos
- [ ] `const` em todos os construtores
- [ ] Estados: `Initial`, `Loading`, `ProductsLoaded`, `SubscriptionsLoaded`, `Success`, `Error`

### View
- [ ] `SafeArea` envolvendo o conteúdo principal
- [ ] Todos os estados tratados no `BlocBuilder`
- [ ] Textos via `context.l10n.<chave>` — zero strings hardcoded
- [ ] `_cubit.close()` chamado no `dispose()`
- [ ] `_cubit.loadProducts()` ou `loadSubscriptions()` chamado no `initState()`
- [ ] **Links de Termos de Uso e Política de Privacidade** presentes na tela de paywall (obrigatório — Apple Guideline 3.1.2(c))
- [ ] `url_launcher` importado na View para abrir os links
- [ ] Strings `premiumTermsOfUse` e `premiumPrivacyPolicy` adicionadas nos arquivos ARB (`app_en.arb` e `app_pt.arb`)

### DI (app_injector.dart)
- [ ] `InAppPurchaseService` → `registerLazySingleton`
- [ ] **Sem back-end**: `StorageService` já registrado (reutilizar existente)
- [ ] **Com back-end**: `PurchaseRemoteDataSource` → `registerLazySingleton`; `PurchaseRepository` → `registerLazySingleton`
- [ ] `PurchaseCubit` → `registerFactory`

### AppInitializer
- [ ] `VerifyLocalPurchase.initialize(...)` chamado antes de `setupDependencies`
- [ ] `useSandbox: flavor != AppFlavor.production` no `AppleConfig`

---

## Passo 5 — Aviso de segurança obrigatório

Sempre informe ao usuário:

> ⚠️ **Nunca confie apenas na validação client-side para desbloquear conteúdo premium.**
> - **Sem back-end**: a verificação via `verify_local_purchase` é uma proteção razoável contra fraudes simples, mas não é infalível. Considere migrar para validação server-side no futuro.
> - **Com back-end**: valide SEMPRE no servidor antes de conceder acesso ao conteúdo. Nunca desbloqueie premium apenas com base no retorno do `purchaseStream` sem passar pelo seu servidor.

---

## Passo 6 — Perguntas de IDs e credenciais

Após gerar o código-esqueleto, lembre o usuário de substituir os placeholders:

```
📋 Substitua no código gerado:
- 'com.example.app'             → Bundle ID / Package Name real do app
- 'your-issuer-id'              → Issuer ID da App Store Connect
- 'your-key-id'                 → Key ID da App Store Connect
- '-----BEGIN PRIVATE KEY-----' → Chave privada da App Store Connect
- '{"type":"service_account"}'  → JSON da conta de serviço do Google Play
- IDs dos produtos               → IDs exatos cadastrados nas lojas
```

---

## Fluxo resumido por tipo de produto

| Tipo | Método de compra | Método de verificação | `completePurchase`? |
|---|---|---|---|
| Consumível | `buyConsumable` | `verifyPurchase` | ✅ Sim (obrigatório Android) |
| Assinatura | `buyNonConsumable` | `verifySubscription` | ✅ Sim |
| Não-consumível permanente | `buyNonConsumable` | `verifySubscription` | ✅ Sim |

---

## Anti-patterns a evitar

- ❌ NÃO crie DataSource/Repository para IAP no modo sem back-end
- ❌ NÃO emita `PurchaseSuccess` direto no `buyProduct` — o resultado vem pelo stream
- ❌ NÃO acesse `InAppPurchaseService` diretamente da View
- ❌ NÃO cancele `_purchaseSubscription` antes do `dispose()` do Cubit
- ❌ NÃO ignore `PurchaseStatus.error`
- ❌ NÃO use `SharedPreferences` diretamente — use sempre `StorageService`
- ❌ NÃO salve `serverVerificationData` localmente — use apenas `localVerificationData`
- ❌ NÃO desbloqueie conteúdo premium sem verificar o receipt (local ou server-side)

---

**Última atualização**: 28 de março de 2026
