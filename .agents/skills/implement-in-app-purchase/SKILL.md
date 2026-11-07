---
name: implement-in-app-purchase
description: >-
  Implementa, revisa ou corrige assinaturas Flutter (mensal/anual, premium,
  Plus) com o plugin oficial in_app_purchase ^3.3.1 na App Store e no Google
  Play: paywall, compra, restauração, renovação, expiração, reembolso,
  pendência e liberação de conteúdo. A assinatura é confirmada pela loja do
  próprio aparelho (StoreKit 2 e Play Billing, sem servidor nem credenciais)
  ou no back-end, pela Cloud Function verifyPurchase do Firebase. Use sempre
  que o pedido envolver in-app purchase/IAP, assinatura, paywall, virar
  premium, restaurar compras, validar compra ou recibo (no aparelho ou no
  servidor), StoreKit ou Play Billing, ou bugs como compra que não completa,
  paywall preso no loading, transação pendente no iOS ou estorno automático
  no Android — mesmo sem citar o plugin. Não use para RevenueCat, Adapty ou
  anúncios.
metadata:
  version: "4.0.0"
  last_modified: 2026-11-05
  in_app_purchase: "^3.3.1"
---

# Assinaturas com in_app_purchase

Esta skill trata **assinaturas** com o plugin oficial
[`in_app_purchase`](https://pub.dev/packages/in_app_purchase) e suas
implementações `in_app_purchase_storekit` (StoreKit 2) e
`in_app_purchase_android` (Play Billing). Para consumíveis e compras
permanentes, faça uma adaptação explícita; não acrescente esses casos ao
exemplo de assinatura por padrão.

## Modo de verificação

Decida o modo antes de implementar. Ele muda apenas **quem confirma a
assinatura**: compra, liquidação, recuperação, finalização, cache, Cubit e
View são os mesmos, e o `PurchaseService` só recebe ou não um `verifyToken`.

| Modo | Quem confirma | Quando | O que implementar |
|---|---|---|---|
| **Local** (padrão) | A loja do aparelho: `SK2Transaction.currentEntitlements()` no iOS e `queryPastPurchases()` no Android | Sem servidor | Os três arquivos, com `PurchaseService()` |
| **Backend** | A callable `verifyPurchase`, que consulta a App Store Server API e a Google Play Developer API | Validar no servidor; exige Firebase no plano Blaze e deploy | Os três arquivos + `functions/` + `PurchaseVerificationRemoteDataSource`, seguindo [`references/backend.md`](references/backend.md) |

- Use o backend sem perguntar quando o pedido falar em back-end, servidor,
  Cloud Function ou Firebase Functions, ou quando `functions/` já exportar
  `verifyPurchase`.
- Use o local sem perguntar quando o pedido disser local, no aparelho ou sem
  servidor.
- Sem sinal claro, inclua a escolha na mensagem de dados que faltam, com o
  trade-off em uma linha: o local não tem infra, mas confia no aparelho e
  não sabe a expiração no Android; o backend consulta as APIs oficiais, mas
  exige Blaze e deploy. Recomende o backend se o projeto já usa Firebase;
  caso contrário, o local.
- No modo backend, leia `references/backend.md` inteiro além dos três
  arquivos.

## Os três arquivos

| Arquivo de referência | Destino sugerido | Responsabilidade |
|---|---|---|
| [`references/purchase_service.dart`](references/purchase_service.dart) | `lib/common/services/purchase_service.dart` | IDs dos planos, `StoreVerification`, verificação no aparelho, compra, liquidação do StoreKit 2, recuperação do Google Play, restauração, `purchaseStream`, acesso e cache |
| [`references/paywall_cubit.dart`](references/paywall_cubit.dart) | `lib/presentation/paywall/paywall_cubit.dart` | `PaywallState`, carregamento, bloqueio de ações e tradução dos eventos do Service |
| [`references/paywall_view.dart`](references/paywall_view.dart) | `lib/presentation/paywall/paywall_view.dart` | Produtos, preço da loja, período, mensagens, links legais e navegação |

Leia os três arquivos antes de implementar. Copie a lógica e adapte os
imports, nomes e DI ao projeto; o exemplo usa imports relativos só para os
arquivos funcionarem juntos dentro de `references/`. Não crie `PurchaseIds`,
`EntitlementService`, `Repository`, `State` separado ou `ServiceImpl` para
duplicar responsabilidades. Os testes de
[`references/purchase_service_test.dart`](references/purchase_service_test.dart)
cobrem as regras abaixo com lojas falsas (`StoreQueries`); leve-os junto e
adapte. O modo backend acrescenta apenas os arquivos de
`references/backend/` listados em `references/backend.md`.

## Dados necessários

Inspecione o app primeiro. Peça em uma mensagem somente os dados que faltam:
IDs reais dos planos, modo de verificação (se ainda não estiver decidido),
URLs de Termos e Privacidade e o comportamento após sucesso. O modo local não
precisa de credenciais. No backend, peça só `issuerId`/`keyId` da Apple e a
região da function: o usuário coloca a chave `.p8` e a service account
direto em `functions/credentials/`, nunca no chat. Os IDs `premium_monthly`
e `premium_yearly` nos exemplos são substituíveis; não publique com eles.
Preço vem de `ProductDetails.price`. O período mensal/anual vem do mapa
`plans` no Service e deve corresponder ao cadastro da loja.

## Integração no app

- Adicione `in_app_purchase: ^3.3.1`, `in_app_purchase_storekit: ^0.4.17`,
  `in_app_purchase_android: ^0.5.0`, `flutter_bloc: ^9.1.1`,
  `shared_preferences: ^2.5.5` e `url_launcher: ^6.3.2` se ainda não houver
  equivalentes; no backend, também `cloud_functions`. As duas implementações
  de loja entram como dependência **direta** porque o Service importa os
  dois pacotes (`depend_on_referenced_packages`).
- `in_app_purchase_storekit` 0.4.17 corrige compras que nunca completam no
  iOS 27 e exige Flutter 3.41+ (Dart 3.11+). Se o Flutter do projeto for
  mais antigo, avise e proponha atualizá-lo; não fixe uma versão anterior do
  plugin.
- iOS 15+ (`platform :ios, '15.0'` no Podfile e o mesmo deployment target no
  Xcode): verificação, token e liquidação dependem do StoreKit 2, o padrão do
  plugin. Ative a capability In-App Purchase e cadastre as assinaturas nas
  duas lojas.
- Registre **uma instância global** de `PurchaseService` —
  `PurchaseService()` no modo local, `PurchaseService(verifyToken:
  remote.verify)` no backend —, chame `await service.start()` cedo no início
  do app e `await service.checkPremium()` na inicialização/retomada. Não
  descarte o Service ao fechar o paywall; a compra pode chegar depois ou em
  outra sessão. Chame `dispose()` só ao encerrar a instância global.
- Crie o Cubit por tela. Passe ao `PaywallView` um `PaywallCopy` preenchido
  com `context.l10n` e as URLs reais. Adicione a rota no roteador existente.
  As mudanças em DI, rota, `pubspec.yaml`, Podfile e ARB são integração, não
  novos módulos da feature.
- Para proteger conteúdo, use o resultado de `service.checkPremium()`: ele
  revalida com a loja e nunca lança. `hasPremium` sozinho é apenas o último
  estado em memória.
- Migrando de uma versão anterior desta skill (pacote
  `verify_local_purchase`): remova o pacote, `AppleConfig`/
  `GooglePlayConfig`, `VerifyLocalPurchase.initialize`/`dispose` e as
  credenciais embutidas (`--dart-define`, assets); troque
  `VerificationResult` por `StoreVerification` (o nome antigo colide com o
  `VerificationResult` do mocktail nos testes) e `getSubscriptionToken` pelo
  token do Service. O cache `iap_subscription_<id>` continua compatível. Se
  as chaves foram publicadas em algum binário, oriente a rotação (seção
  "Rotação de chaves" de `references/backend/functions/README.md`).

## Regras de compra e verificação

- `buyNonConsumable` inicia a assinatura no plugin. Seu `Future` não
  confirma pagamento. O Service processa `purchased` e `restored` apenas
  pelo `purchaseStream`.
- O token da assinatura é o `originalTransactionId` do JSON da transação
  (`localVerificationData`) na App Store — o mesmo em renovações, trocas de
  plano e restaurações — e o purchaseToken (`serverVerificationData`) no
  Google Play. A loja vem de `verificationData.source`, nunca de
  `Platform`, para o código ser testável em qualquer máquina.
- Conceda acesso somente quando a verificação for válida, o produto
  pertencer ao mapa `plans` e `expiresAt` estiver no futuro. No modo local,
  estar nos direitos atuais da loja é a confirmação: o iOS informa a
  expiração; o Play Billing não informa nenhuma, e a confirmação vale 3 dias
  (`_deviceConfirmation`), renovada a cada consulta. O mesmo prazo cobre a
  carência da Apple, em que a transação já venceu mas o StoreKit ainda
  concede.
- No iOS/StoreKit 2, `buy*` recusa abrir a folha com
  `storekit_duplicate_product_object` quando existe transação **não
  finalizada** do mesmo produto — o caso de quem assinou, cancelou e tenta
  assinar o mesmo plano de novo (o outro plano abre normalmente, o que
  despista o diagnóstico). Antes de comprar, liquide a fila:
  `SK2Transaction.unfinishedTransactions()` do produto vira
  `SK2PurchaseDetails` com `status: purchased` (só assim o
  `completePurchase` finaliza) e passa pela mesma verificação do stream.
  Antiga ainda válida → concede e finaliza, sem cobrar de novo;
  expirada/inválida → finaliza e segue para a compra; verificação
  indisponível → **não** finaliza e **não** abre a compra. Como rede de
  segurança, `PlatformException` com esse código dispara nova liquidação e
  uma única tentativa extra.
- Depois de salvar o acesso, chame `completePurchase` se a compra estiver
  pendente de finalização. Verificação inválida não concede: no iOS,
  finalize a transação (senão ela bloqueia a recompra do produto); no
  Android, **não** reconheça — o Google estorna em 3 dias a compra que o app
  não confirmou, o desfecho certo para uma compra que não foi validada.
  Falha de rede ou de configuração, timeout, `pending` e `unknown` não
  finalizam nem reconhecem: a compra fica para nova tentativa com backoff.
- O Google Play **não** reentrega pelo `purchaseStream` a compra que ficou
  sem `completePurchase` (app fechado durante a verificação, pendência paga
  depois) e a estorna em 3 dias. Por isso `refreshAccess()` consulta
  `queryPastPurchases()` e passa as compras de `plans` ainda não
  reconhecidas pela mesma verificação. O iOS reentrega as não finalizadas no
  stream a cada abertura.
- `pending` não concede; `canceled` libera a tela sem erro; `error` mostra
  falha.
- No Android, fechar a folha do Google Play sem comprar (ou um erro sem
  compra) chega no `purchaseStream` com `productID: ''` e `purchaseID: ''`.
  **Não** filtre esse evento pelo mapa `plans`: trate `canceled`/`error`
  com `productID` vazio como deste paywall, ou o Cubit fica `busy` até o
  watchdog, com o botão de fechar desabilitado. Produtos de outras features
  (ID não vazio fora de `plans`) continuam ignorados.
- A restauração chega num lote só. Vazio, ou só com produtos de outras
  features, emite `nothingToRestore`; exceção da loja emite `restoreFailed`
  (o StoreKit 2 lança `storekit2_restore_failed` quando há compra não
  verificável).
- `checkPremium()` revalida renovação, expiração e reembolso. Chamadas
  simultâneas (boot, splash, retomada) dividem a mesma execução, e um
  registro confirmado há menos de 12 h e a mais de 24 h do fim não consulta
  a loja — no backend, cada consulta é uma chamada da function. Reembolso no
  iOS também chega pelo stream.
- Compras, verificações e cache rodam numa fila única (`_serialized`). Ao
  estender o Service, não chame `_serialized` de dentro de uma tarefa da
  fila: ela esperaria por si mesma.
- O Service mantém o listener de compras enquanto o app vive. O Cubit
  cancela só a própria escuta ao fechar a tela, usa um watchdog para não
  deixar a tela bloqueada quando a loja não responde (sem declarar a compra
  como perdida) e ignora avisos de verificações em segundo plano quando não
  há ação em curso. A View navega apenas após o Service emitir `granted`.

## Segurança e limites

- **Local:** nenhum segredo vai no binário. O StoreKit 2 confere a
  assinatura da Apple no aparelho e os dados do Play Billing vêm do app da
  Play Store, mas a decisão é do aparelho: jailbreak, root ou um app
  modificado podem burlá-la. No Android, sem a data da loja, um aparelho
  offline mantém o acesso até 3 dias após a última confirmação.
- **Backend:** as credenciais da loja ficam no servidor e a consulta usa as
  APIs oficiais, mas a decisão de acesso continua no aparelho (seção 6 de
  `references/backend.md`).
- Vincular a assinatura a contas próprias entre aparelhos ou impedir o
  compartilhamento entre usuários exige um servidor que grave o acesso por
  conta; isso não faz parte de nenhum dos dois modos.
- Não confie em um `bool premium` solto em `SharedPreferences` nem em
  `localVerificationData` sem confirmação da loja. O registro
  `iap_subscription_<id>` é só cache do aparelho; duas contas do app no
  mesmo aparelho acessam a assinatura da mesma conta da loja.
- Em aparelho novo ou após reinstalação, sem token local, `checkPremium()`
  retorna falso até a pessoa usar **Restaurar compras**. A assinatura
  pertence à conta Apple/Google e pode ser restaurada em outros aparelhos
  dessa conta; este fluxo não trava a compra ao hardware.

## Validação

Formate e rode análise estática e os testes pertinentes, incluindo a
adaptação de `references/purchase_service_test.dart`. No modo backend, rode
também `cd functions && npm install && npm run build && npm test`; não faça
deploy sem pedido explícito e entregue ao usuário os passos manuais de
`references/backend.md` (credenciais, permissões nas lojas, deploy). Não
inicie app, simulador, servidor ou teste visual.

Informe ao usuário para testar manualmente, nas contas de teste das duas
lojas (sandbox/TestFlight e testadores de licença do Google Play):

- assinatura mensal e anual, inclusive num aparelho com iOS 27;
- fechar a folha sem comprar (no Android, a tela deve voltar na hora) e
  compra pendente;
- restauração com e sem compra, e reinstalação seguida de Restaurar compras;
- offline durante a verificação;
- renovação, expiração e reembolso;
- recompra do mesmo plano após cancelamento no iOS (transação órfã);
- no Android, fechar o app logo depois de pagar e reabrir: o acesso deve
  aparecer e o pedido não pode ser estornado em 3 dias;
- abertura dos links legais.
