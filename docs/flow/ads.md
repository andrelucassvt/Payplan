---
generated_at: 2026-11-07
source_commit: 93ab5b5
source_state: dirty
verified_at: 2026-11-07
status: current
---

# Flow: Anúncios (AdMob)

> **Resumo:** Inicialização do Google Mobile Ads, exibição de banners fixos (`AdmobBannerWidget`) nas listas de Dívidas, Devedores e Orçamentos e do App Open Ad ao tocar em "Editar fatura", tudo suprimido quando `UserController.user.value.isPlus` é `true`; IDs de produção centralizados em `AdConfig`, sem IDs de teste.

---

## Visão Geral

O SDK é inicializado em `main()` com `await AdService().initialize()` antes do `runApp`, então qualquer widget de anúncio já encontra o `MobileAds` pronto. Os IDs dos blocos (ad units) ficam em `AdConfig`, que escolhe entre Android e iOS via `Platform` e sempre devolve IDs de **produção**: não há `kDebugMode`, IDs de teste do Google nem `RequestConfiguration`/`testDeviceIds` em nenhum lugar de `lib/`.

Há dois formatos em uso. **Banners** (`AdmobBannerWidget`, `AdSize.banner` 320x50) aparecem intercalados nas listas: abaixo do 1º e do 2º card em Dívidas (`HomeView`) e em Orçamentos (`OrcamentoView`), e abaixo do 1º card em Devedores (`DevedoresView`). O **App Open Ad** (`AppOpenAdService`, singleton) é pré-carregado uma vez no `HomeBase` e exibido não na abertura do app, mas quando um usuário não-Plus toca em "Editar fatura" num card de dívida (`HomeCardDivida`).

O gating premium é sempre feito na UI: cada ponto de anúncio fica dentro de um `ValueListenableBuilder` sobre `UserController.user` e checa `user.isPlus`. O valor começa em `false` (default do `ValueNotifier`) e é corrigido assim que `HomeCubit.buscarIsPlus()` lê `'isPlus'` do `SharedPreferences`; uma compra/restauração no `PlusCubit` faz `setUser(isPlus: true)` e os anúncios somem em tempo real.

Configuração nativa: o App ID está em `AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`, com permissão `AD_ID`) e em `Info.plist` (`GADApplicationIdentifier`). Não há fluxo de consentimento (UMP), ATT nem `SKAdNetworkItems`.

## Passo a Passo

1. **Bootstrap** — `lib/main.dart` → `main()` (linha 10)
   `WidgetsFlutterBinding.ensureInitialized()` e então `await AdService().initialize()`, antes de `ThemeController.init()` e `runApp`. O início do app espera a inicialização do SDK.
2. **Inicialização do SDK** — `lib/src/util/service/ads/ad_service.dart` → `AdService.initialize()`
   Chama `MobileAds.instance.initialize()` uma única vez (flag estática `_initialized`). Não trata exceção: se falhar, o erro sobe para `main()`.
3. **Shell da Home** — `lib/src/features/home/view/home_base.dart` → `_HomeBaseState.initState()`
   Dispara `_homeCubit.buscarIsPlus()` (linha 49) e, num `addPostFrameCallback` (linhas 54–56), `AppOpenAdService.instance.load()`. O load **não** checa `isPlus`: o App Open Ad é baixado também para usuários Plus.
4. **Status premium** — `lib/src/features/home/cubit/home_cubit.dart` → `buscarIsPlus()` (linha 226)
   Lê `prefs.getBool('isPlus') ?? false` e chama `UserController.setUser(...)` (`lib/src/util/entity/user_entity.dart`), que atualiza o `ValueNotifier` e regrava a mesma chave. Até isso terminar, `isPlus` vale `false`.
5. **Pré-carga do App Open** — `lib/src/util/service/ads/app_open_ad_service.dart` → `AppOpenAdService.load()`
   `AppOpenAd.load` com `AdConfig.appOpen`; em `onAdLoaded` guarda o anúncio em `_appOpenAd`, em `onAdFailedToLoad` zera e só faz `log`. Sem retry.
6. **Banners nas listas** — `ListView.builder` + `ValueListenableBuilder(UserController.user)` em cada View:
   - `lib/src/features/home/view/home_view.dart` (linhas 134–143): se `!user.isPlus`, `AdmobBannerWidget(AdConfig.homeBanner1)` após o índice 0 e `AdmobBannerWidget(AdConfig.homeBanner2)` após o índice 1.
   - `lib/src/features/orcamento/view/orcamento_view.dart` (linhas 99–108): mesmo padrão, reaproveitando `homeBanner1`/`homeBanner2`.
   - `lib/src/features/devedores/view/devedores_view.dart` (linhas 190–193): `AdmobBannerWidget(AdConfig.devedoresBanner)` só após o índice 0.
   Com lista vazia (estado vazio da View) nenhum banner é renderizado.
7. **Carga e render do banner** — `lib/src/util/widgets/admob_banner_widget.dart` → `_AdmobBannerWidgetState._loadAd()`
   No `initState` cria `BannerAd(...)..load()`. Enquanto não carregou (ou se falhou) o `build` devolve `SizedBox.shrink()`, sem reservar espaço; ao carregar, `setState` e renderiza `AdWidget` em `SizedBox` do tamanho do `AdSize` com `padding` inferior de 5. `dispose()` libera o `BannerAd`.
8. **Exibição do App Open** — `lib/src/features/home/widgets/home_card_divida.dart` → `_editarFaturaBottomSheet(bool isPlus)` (linhas 776–778)
   O chip "Editar fatura" (linha 376) passa `user.isPlus`; se `false`, chama `AppOpenAdService.instance.show()` e, em seguida, abre o `showModalBottomSheet` de edição de fatura de qualquer forma (o anúncio cobre o bottom sheet, que fica aberto atrás).
9. **Consumo do anúncio** — `app_open_ad_service.dart` → `AppOpenAdService.show()`
   Se `_appOpenAd == null`, só faz `log('ad not ready')`; senão chama `show()` e zera `_appOpenAd`. Nenhum `load()` é chamado depois, então o App Open aparece **no máximo uma vez por sessão**.
10. **Upsell "Sem anúncios"** — `lib/src/features/home/widgets/home_total_widget.dart` (linhas 566–576)
    Para não-Plus, mostra o chip `AppStrings.semAnuncio` que abre `PlusView` num bottom sheet. Quando a compra conclui, `PlusCubit._processPurchaseUpdates` (`lib/src/features/plus/cubit/plus_cubit.dart`, linha 36) faz `UserController.setUser(UserEntity(isPlus: true))`; todos os `ValueListenableBuilder` reconstroem, os `AdmobBannerWidget` saem da árvore (e são descartados) e o próximo "Editar fatura" não chama `show()`.

### Caminhos alternativos

- **Banner falha ao carregar:** `onAdFailedToLoad` em `AdmobBannerWidget` faz `log`, `ad.dispose()` e `_bannerAd = null`; o espaço continua colapsado (`SizedBox.shrink`). Não há retry; uma nova tentativa só ocorre quando o item é recriado (ex.: rolar para fora e de volta, já que `ListView.builder` descarta itens fora da tela).
- **App Open não carregou ou já foi usado:** `show()` só registra `ad not ready` e o bottom sheet abre normalmente.
- **Plataforma diferente de Android/iOS:** todos os getters de `AdConfig` lançam `UnsupportedError('Plataforma não suportada para anúncios')`.
- **Usuário Plus na abertura:** por alguns instantes `isPlus` é `false` (default) e os banners podem começar a carregar; quando `buscarIsPlus()` atualiza o notifier, os widgets são removidos e o `dispose()` libera os anúncios.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Bootstrap | `lib/main.dart` | Aguarda `AdService().initialize()` antes do `runApp` |
| Serviços | `lib/src/util/service/ads/ad_service.dart` | Inicializa `MobileAds` uma única vez |
| Serviços | `lib/src/util/service/ads/app_open_ad_service.dart` | Singleton que pré-carrega e exibe (uma vez) o App Open Ad |
| Configuração | `lib/src/util/service/ads/ad_config.dart` | IDs de produção por plataforma: `homeBanner1`, `homeBanner2`, `devedoresBanner`, `appOpen` |
| Apresentação (widget) | `lib/src/util/widgets/admob_banner_widget.dart` | Banner fixo `AdSize.banner`, colapsado até carregar; único widget de anúncio em uso |
| Apresentação | `lib/src/features/home/view/home_base.dart` | Dispara `buscarIsPlus()` e `AppOpenAdService.instance.load()` |
| Apresentação | `lib/src/features/home/view/home_view.dart` | Banners após o 1º e o 2º card de dívida |
| Apresentação | `lib/src/features/orcamento/view/orcamento_view.dart` | Banners após o 1º e o 2º card de orçamento (mesmos IDs da Home) |
| Apresentação | `lib/src/features/devedores/view/devedores_view.dart` | Banner após o 1º card de devedor |
| Apresentação | `lib/src/features/home/widgets/home_card_divida.dart` | Gatilho do App Open em `_editarFaturaBottomSheet` |
| Apresentação | `lib/src/features/home/widgets/home_total_widget.dart` | Chip "Sem anúncios" que abre `PlusView` |
| Estado | `lib/src/util/entity/user_entity.dart` | `UserController.user` (`ValueNotifier<UserEntity>`) e persistência de `'isPlus'` |
| Estado | `lib/src/features/home/cubit/home_cubit.dart` | `buscarIsPlus()` carrega `'isPlus'` do `SharedPreferences` |
| Estado | `lib/src/features/plus/cubit/plus_cubit.dart` | Marca `isPlus: true` em compra/restauração, desligando os anúncios |
| Config. nativa | `android/app/src/main/AndroidManifest.xml` | `com.google.android.gms.ads.APPLICATION_ID` + permissão `com.google.android.gms.permission.AD_ID` |
| Config. nativa | `ios/Runner/Info.plist` | `GADApplicationIdentifier` (`NSUserTrackingUsageDescription` comentado) |
| Dependência | `pubspec.yaml` | `google_mobile_ads: ^6.0.0` |

Não há teste cobrindo anúncios (o único teste, `test/util/entity/orcamento_entity_test.dart`, é de `OrcamentoEntity`).

## Regras de Negócio Relevantes

- **Usuário Plus não vê anúncio nenhum** — `home_view.dart`, `orcamento_view.dart`, `devedores_view.dart`, `home_card_divida.dart`: todos os pontos de banner e o `show()` do App Open são condicionados a `!user.isPlus`. Esse é o benefício vendido pelo chip "Sem anúncios" (`home_total_widget.dart`).
- **Posições fixas dos banners** — Dívidas e Orçamentos: dois banners, após os itens 0 e 1; Devedores: um banner, após o item 0. Listas com um só item mostram apenas o primeiro banner.
- **App Open atrelado a "Editar fatura", não à abertura do app** — `home_card_divida.dart` → `_editarFaturaBottomSheet`: o anúncio "de abertura" funciona como um intersticial disparado por uma ação de edição, no máximo uma vez por sessão (`AppOpenAdService.show()` zera o anúncio e não recarrega).
- **IDs de produção em todos os builds** — `ad_config.dart`: não existe troca por IDs de teste em debug.

## Dependências Externas

- **Google Mobile Ads SDK** (`google_mobile_ads ^6.0.0`) — `MobileAds`, `BannerAd`, `AppOpenAd`, `AdWidget`.
- **AdMob** — publisher `ca-app-pub-3652623512305285`; App IDs distintos por plataforma no manifest/plist.
- **`shared_preferences`** — chave `'isPlus'`, que decide se os anúncios aparecem.

## Observações

- **Sem IDs de teste:** rodar o app em debug ou em emulador solicita anúncios reais de produção, o que pode gerar impressões/cliques inválidos na conta AdMob. Não há `kDebugMode`, IDs de exemplo do Google nem `testDeviceIds`.
- **Código órfão:** `lib/src/util/service/open_app_admob.dart` (`AppOpenAdManager`) não é importado em lugar nenhum e duplica, hardcoded, os mesmos IDs de `AdConfig.appOpen`. `lib/src/util/widgets/admob_adaptive_banner.dart` (`AdmobAdaptiveBanner`) e `lib/src/util/widgets/admob_native_banner.dart` (`AdmobNativeBanner`) também não são usados. Além disso, `AdmobAdaptiveBanner` carrega em `didChangeDependencies`, o que criaria um `BannerAd` novo a cada mudança de dependência sem descartar o anterior.
- **App Open sem `fullScreenContentCallback`:** `AppOpenAdService` não descarta o anúncio após fechar, não recarrega e não checa a validade do anúncio pré-carregado (o Google recomenda descartar após cerca de 4h). Também é carregado mesmo para usuários Plus.
- **Ordem App Open + bottom sheet:** `show()` e `showModalBottomSheet` são chamados em sequência; o anúncio aparece por cima de um bottom sheet já aberto, com teclado/foco possivelmente ativos.
- **Ad units compartilhados:** `OrcamentoView` reusa `homeBanner1`/`homeBanner2`, então os relatórios do AdMob não separam receita de Dívidas e de Orçamentos.
- **Privacidade/consentimento:** não há UMP (`ConsentInformation`/`ConsentForm`), `NSUserTrackingUsageDescription` está comentado no `Info.plist` e não há `SKAdNetworkItems`. Em iOS os anúncios serão sempre não personalizados por ATT, e na UE/Reino Unido falta o fluxo de consentimento exigido pelo AdMob.
- **Gating só liga, nunca desliga:** em `lib/` nada grava `isPlus: false` (só `buscarIsPlus` relendo o valor salvo e `PlusCubit` gravando `true`). Uma assinatura expirada ou reembolsada continua sem anúncios enquanto a flag local for `true`.
- **Flash de banners para Plus:** como `UserController.user` começa com `isPlus: false` e `buscarIsPlus()` é assíncrono, pode haver requisições de banner logo na abertura para usuários Plus, descartadas assim que o valor é corrigido.
