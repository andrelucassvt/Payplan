---
generated_at: 2026-11-07
source_commit: 93ab5b5
source_state: dirty
verified_at: 2026-11-07
status: current
---

# Flow: Plus (remoção de anúncios via compra única)

> **Resumo:** Compra única não consumível `sem_anuncio` (in_app_purchase) aberta num bottom sheet a partir do chip "Sem anúncios" da Home. Cobre compra, restauração e o tratamento de pendente/erro/cancelado no `PlusCubit`, e a gravação de `isPlus` via `UserController` em `SharedPreferences`, que esconde os banners e o App Open Ad. Não há validação de recibo nem expiração.

## Visão Geral

O "Plus" do Payplan não é uma assinatura: é um produto **não consumível** (`InAppPurchaseService.productId = 'sem_anuncio'`, comprado com `buyNonConsumable`) cujo único efeito é remover anúncios. O usuário toca no chip "Sem anúncios" do card de totais da Home (`HomeTotalWidget`). Esse chip só aparece para quem ainda não é Plus. O toque abre `PlusView` num `showModalBottomSheet` com 80% da altura da tela, e não via `Navigator.push`.

`PlusView` cria o próprio `PlusCubit(InAppPurchaseService())`. O construtor do Cubit já assina o `purchaseStream` do plugin, e o `initState` chama `loadProducts()`. Conforme o estado, a tela mostra um loading, a mensagem "loja indisponível", a vitrine (`PlusShopContent`, com o botão de preço, os links de EULA e privacidade e "Restaurar compras") ou a confirmação (`PlusPremiumContent`).

Comprar e restaurar só **disparam** a operação na loja. O resultado chega de forma assíncrona pelo `purchaseStream` e é tratado em `PlusCubit._processPurchaseUpdates`. Nos status `purchased` e `restored`, o Cubit chama `UserController.setUser(UserEntity(isPlus: true))`, que atualiza o `ValueNotifier` global e grava `prefs.setBool('isPlus', true)`. Em seguida finaliza a transação (`completePurchase`) e emite `PlusPremium`. A `PlusView` mostra um SnackBar e troca o conteúdo para a confirmação.

O status premium é **apenas um booleano local**. No boot, `HomeBase.initState` chama `HomeCubit.buscarIsPlus()`, que lê `'isPlus'` das prefs e popula o `UserController`. As telas que exibem anúncios escutam `UserController.user` com `ValueListenableBuilder` e omitem os banners quando `isPlus == true`. Nenhum ponto do código consulta a loja no boot, valida o recibo ou revoga o status.

## Passo a Passo

1. **Boot / estado global**: `lib/src/features/home/view/home_base.dart` → `initState` (l. 49) → `HomeCubit.buscarIsPlus()` (`lib/src/features/home/cubit/home_cubit.dart:226`)
   Lê `prefs.getBool('isPlus') ?? false` e chama `UserController.setUser`. O valor inicial do `ValueNotifier` é `isPlus: false`, e o método é `void async` sem `await`. Por isso as telas renderizam primeiro como não Plus e só depois recebem o valor persistido.
2. **Ponto de entrada**: `lib/src/features/home/widgets/home_total_widget.dart:563-578` → `ValueListenableBuilder(UserController.user)`
   Se `user.isPlus`, devolve `SizedBox.shrink()` e o chip não existe. Caso contrário, o `GestureDetector` abre `showModalBottomSheet(isScrollControlled: true, useSafeArea: true, maxHeight: 80%)` com `const PlusView()`.
3. **View**: `lib/src/features/plus/view/plus_view.dart` → `_PlusViewState`
   `late final _cubit = PlusCubit(InAppPurchaseService())`. O `initState` dispara `_cubit.loadProducts()`, e o `dispose` chama `_cubit.close()`, que cancela a assinatura do stream.
4. **Cubit, assinatura do stream**: `lib/src/features/plus/cubit/plus_cubit.dart` → construtor → `_listenToPurchaseStream()` (l. 20)
   Assina `_service.purchaseStream` (`InAppPurchase.instance.purchaseStream`) com `_processPurchaseUpdates`. O listener só existe enquanto a `PlusView` está aberta.
5. **Cubit, carregar produto**: `PlusCubit.loadProducts()` (l. 52) → `InAppPurchaseService.loadProducts()` (`lib/src/util/service/in_app_purchase/in_app_purchase_service.dart:11`)
   Emite `PlusLoading`. O service checa `isAvailable()` e devolve `[]` se a loja não estiver disponível. Se estiver, faz `queryProductDetails({'sem_anuncio'})` e devolve `productDetails`. No Cubit, a ordem dos testes é esta:
   - lista vazia → `PlusStoreUnavailable` (cobre loja indisponível **e** ID não encontrado; `notFoundIDs`/`error` da resposta são ignorados);
   - `UserController.user.value.isPlus` → `PlusPremium()`;
   - caso contrário → `PlusProductsLoaded(products)`;
   - exceção → `PlusPurchaseError(message: 'Erro ao carregar produtos: $e', products: [])`.
6. **UI da vitrine**: `lib/src/features/plus/content/plus_shop_content.dart` → `PlusShopContent`
   O botão mostra `'${AppStrings.removerAnunciosPor} ${products.first.price}'` e fica desabilitado, com spinner, quando `isProcessing`. Os dois `TextButton` abrem `launchUrl(..., mode: LaunchMode.externalApplication)`: a EULA padrão da Apple (`https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`) e a "política de privacidade" (`https://github.com/andrelucassvt/Payplan/blob/main/README.md`). O `InkWell` "Restaurar compras" chama `onRestore`.
7. **Compra**: `PlusView` `onBuy` → `PlusCubit.buyProduct(products.first)` (l. 73) → `InAppPurchaseService.buy` (l. 18)
   Emite `PlusProductsLoaded(isProcessing: true)` e chama `buyNonConsumable(PurchaseParam(productDetails))`. O retorno indica só que a folha da loja foi aberta. Se a chamada lançar exceção, emite `PlusPurchaseError('Erro ao iniciar compra: $e', products)`.
8. **Restauração**: `onRestore` → `PlusCubit.restorePurchases()` (l. 85) → `InAppPurchaseService.restorePurchases` (l. 26)
   Mesmo padrão: `isProcessing: true` e `_iap.restorePurchases()`. As compras restauradas chegam pelo stream com status `restored`. Se a chamada lançar exceção, emite `PlusPurchaseError('Erro ao restaurar compras: $e')`.
9. **Resultado da loja**: `PlusCubit._processPurchaseUpdates` (l. 26) itera cada `PurchaseDetails`:
   - `pending` → `break`: nada é emitido e o botão continua com spinner;
   - `purchased` / `restored` → `UserController.setUser(UserEntity(isPlus: true))` → `await _service.completePurchase(purchase)` → `emit(PlusPremium(isRestored: status == restored))`;
   - `error` → `PlusPurchaseError(message: purchase.error?.message ?? 'Erro ao processar compra.', products: _products)`;
   - `canceled` → `PlusProductsLoaded(products: _products)`, que volta à vitrine sem spinner.
10. **Persistência do status**: `lib/src/util/entity/user_entity.dart:34` → `UserController.setUser`
    Atribui `user.value` (instância nova, então o `ValueNotifier` sempre notifica) e grava `prefs.setBool('isPlus', ...)`. A chamada é `void async` e o chamador não aguarda a gravação.
11. **Feedback na View**: `PlusView` → `BlocConsumer.listener` (l. 35-49)
    `PlusPurchaseError` mostra um SnackBar com `state.message`. `PlusPremium` mostra `AppStrings.comprasRestauradas` se `isRestored` ou `AppStrings.compraRealizada` caso contrário. O `builder` (l. 66-97) troca o body para `PlusPremiumContent`. Um `PlusPurchaseError` com produtos volta à vitrine; sem produtos, mostra `lojaIndisponivel`.
12. **Efeito no resto do app**: os `ValueListenableBuilder(UserController.user)` reconstroem e somem com os anúncios (ver Regras de Negócio). O chip de entrada da Home também desaparece.

### Caminhos alternativos

- **Loja indisponível ou produto não cadastrado**: `InAppPurchaseService.loadProducts` devolve `[]`, o Cubit emite `PlusStoreUnavailable` e a View exibe `AppStrings.lojaIndisponivel`.
- **Exceção ao consultar produtos**: `PlusPurchaseError` com `products: []`. A View mostra um SnackBar com a mensagem técnica e o texto `lojaIndisponivel` no body.
- **Usuário cancela a folha da loja**: o status `canceled` reemite `PlusProductsLoaded` e o botão é reabilitado.
- **Compra pendente** (Ask to Buy, pagamento pendente no Play): não há mudança de estado e o botão fica com spinner até chegar outro status pelo stream, se a `PlusView` ainda estiver aberta.
- **Restaurar sem compras anteriores**: nenhum `PurchaseDetails` é processado (o laço não roda), então nenhum estado novo é emitido. O spinner continua e não aparece nenhuma mensagem de "nada para restaurar".
- **Falha da loja durante a compra**: o status `error` emite `PlusPurchaseError`. A View mostra um SnackBar e mantém a vitrine com `isProcessing: false`.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Apresentação (entrada) | `lib/src/features/home/widgets/home_total_widget.dart` | Chip "Sem anúncios", visível só se `!isPlus`. Abre `PlusView` em `showModalBottomSheet` (l. 563-578) |
| Apresentação | `lib/src/features/plus/view/plus_view.dart` | Cria o `PlusCubit`, carrega os produtos, alterna o body por estado e mostra os SnackBars de resultado |
| Apresentação | `lib/src/features/plus/content/plus_shop_content.dart` | Vitrine: botão com `products.first.price`, links de EULA e privacidade (`url_launcher`), "Restaurar compras" |
| Apresentação | `lib/src/features/plus/content/plus_premium_content.dart` | Tela de confirmação (`AppStrings.aproveiteSemAnuncios`) |
| Estado | `lib/src/features/plus/cubit/plus_cubit.dart` | Assina o `purchaseStream`, trata os status, libera o Plus e finaliza a transação |
| Estado | `lib/src/features/plus/cubit/plus_state.dart` | Estados selados: `PlusInitial`, `PlusLoading`, `PlusProductsLoaded(products, isProcessing)`, `PlusPremium(isRestored)`, `PlusStoreUnavailable`, `PlusPurchaseError(message, products)` |
| Serviços | `lib/src/util/service/in_app_purchase/in_app_purchase_service.dart` | Wrapper fino de `InAppPurchase.instance`: product ID `sem_anuncio`, `loadProducts`, `buy` (não consumível), `completePurchase`, `restorePurchases` |
| Estado global / dados | `lib/src/util/entity/user_entity.dart` | `UserEntity(isPlus)` e `UserController` (`ValueNotifier` estático + `prefs.setBool('isPlus')`) |
| Estado / dados (boot) | `lib/src/features/home/cubit/home_cubit.dart` | `buscarIsPlus()` (l. 226): lê `'isPlus'` das prefs no boot e popula o `UserController` |
| Configuração | `lib/src/util/strings/app_strings.dart` (l. 83-92) + `lib/i18n/*.json` | Textos da feature (`semAnuncios`, `removerAnunciosPor`, `lojaIndisponivel`, `comprasRestauradas`, `compraRealizada` etc.), presentes nos 3 idiomas |

Testes: não há teste para este fluxo. O único teste do projeto (`test/util/entity/orcamento_entity_test.dart`) não toca em Plus, `UserController` nem IAP.

## Regras de Negócio Relevantes

- **Plus = remover anúncios, compra única vitalícia**: `in_app_purchase_service.dart:6,20`. Há um único produto, `sem_anuncio`, comprado com `buyNonConsumable`. Não existe plano mensal/anual nem expiração.
- **Qualquer `purchased`/`restored` libera o Plus**: `plus_cubit.dart:33-40`. O status vem do aparelho e é aceito sem validar recibo (`verificationData` não é usado) e sem conferir `purchase.productID`.
- **O status premium é um booleano local persistente**: `user_entity.dart:34-38` grava `'isPlus'` em `SharedPreferences`, e `home_cubit.dart:226-231` relê esse valor no boot. Depois de concedido, nenhum código volta a gravar `false`. Reembolso ou estorno não revogam o status, e uma reinstalação perde o status até o usuário restaurar.
- **Restauração manual**: `plus_shop_content.dart:96-105`. O link "Restaurar compras" é a única forma de recuperar o Plus (outro aparelho, reinstalação); não há restauração automática no boot.
- **O ponto de venda some para quem já é Plus**: `home_total_widget.dart:566`.
- **Anúncios condicionados a `!isPlus`**, sempre via `ValueListenableBuilder(UserController.user)`:
  - `lib/src/features/home/view/home_view.dart:134-142`: `AdmobBannerWidget` `homeBanner1`/`homeBanner2` após o 1º e o 2º card de dívida;
  - `lib/src/features/devedores/view/devedores_view.dart:190-193`: `devedoresBanner` após o 1º devedor;
  - `lib/src/features/orcamento/view/orcamento_view.dart:99-105`: `homeBanner1`/`homeBanner2` após o 1º e o 2º orçamento;
  - `lib/src/features/home/widgets/home_card_divida.dart:776-778`: `AppOpenAdService.instance.show()` ao abrir "Editar fatura", só se `!isPlus`.
- **Links legais obrigatórios na vitrine**: `plus_shop_content.dart:59-92`. EULA padrão da Apple e política de privacidade (README do GitHub), abertos fora do app.

## Dependências Externas

- `in_app_purchase: ^3.2.3` (StoreKit no iOS, Google Play Billing no Android). O produto `sem_anuncio` precisa estar cadastrado como não consumível no App Store Connect e no Play Console. Esse cadastro fica fora do repositório e não foi verificado.
- `url_launcher: ^6.3.1`: abre a EULA e a política de privacidade no navegador externo.
- `shared_preferences`: chave `'isPlus'`.
- `google_mobile_ads` (indiretamente): os banners e o App Open Ad são suprimidos pelo `isPlus`.

## Observações

- **Correção do contexto anterior**: `PlusView` é aberta por `showModalBottomSheet` (`home_total_widget.dart:568`), **não** por `Navigator.push`.
- **Listener só existe com a tela aberta**: o `purchaseStream` é assinado no construtor do `PlusCubit` e cancelado no `close()`. Não há listener global em `main.dart` nem em `HomeBase`. Se a `PlusView` for fechada no meio de uma compra, o resultado não é processado: o Plus não é liberado e `completePurchase` não é chamado. O mesmo vale para transações que a loja reentrega no início do app (pendentes aprovadas depois, compras interrompidas). Tudo isso só é tratado quando o usuário reabre a `PlusView`. No Android, uma compra não reconhecida (*acknowledge*) em até 3 dias é estornada automaticamente pelo Play.
- **`completePurchase` sem checar `pendingCompletePurchase`**: só é chamado em `purchased`/`restored` (`plus_cubit.dart:37`). Em `error`, a transação nunca é finalizada, mesmo quando o plugin sinaliza que precisa ser (comum no iOS).
- **Sem validação de recibo e sem revogação**: não há verificação local nem de servidor, nem checagem do `productID`. Como o status fica salvo como `true` e nunca é rechecado, reembolsos mantêm o usuário sem anúncios.
- **Spinner preso**: tanto `pending` quanto "restaurar sem compras" deixam `isProcessing: true` indefinidamente, sem nenhum feedback.
- **Ordem em `loadProducts`**: `_products.isEmpty` é testado antes de `isPlus`. Um usuário Plus com a loja fora do ar veria "loja indisponível". Na prática isso não acontece porque o chip de entrada some para usuários Plus.
- **Várias transações em um lote** (por exemplo, restauração que devolve mais de um item): o laço emite `PlusPremium` por item, o que gera SnackBars repetidos.
- **Strings hardcoded em pt-BR** no Cubit (`'Erro ao processar compra.'`, `'Erro ao carregar produtos: $e'`, `'Erro ao iniciar compra: $e'`, `'Erro ao restaurar compras: $e'`), exibidas ao usuário com a exceção crua. Isso contraria a regra de i18n do projeto.
- **Corrida no boot**: `buscarIsPlus()` e `UserController.setUser` são `void async` sem `await`. O primeiro frame usa `isPlus: false`, então os banners podem começar a ser montados antes de o valor persistido chegar. `AppOpenAdService.instance.load()` (`home_base.dart:55`) roda sempre, independentemente do `isPlus`; só o `show()` é condicionado.
- `// ignore: unawaited_futures` em `plus_cubit.dart:35` não tem efeito, porque `setUser` retorna `void`, não `Future`.
- O link "Termo de privacidade" aponta para o `README.md` do GitHub, e o link da EULA da Apple também aparece no Android.
- `UserEntity` não segue a convenção de entidades do projeto (não é `@immutable`, não tem `const`, `==` nem `hashCode`).
