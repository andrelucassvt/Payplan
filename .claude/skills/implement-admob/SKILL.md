---
name: implement-admob
description: Implements Google AdMob ads (banner, native, interstitial) in Flutter following the project architecture. Use whenever adding or modifying ad-related files, integrating the AdMob SDK, adding monetization via ads, creating banner or native ad widgets, managing interstitial ad lifecycle, or centralizing ad unit IDs. Covers AdConfig centralized IDs, AdService SDK init, InterstitialAdService lifecycle, AdBannerWidget, AdNativeWidget, DI registration, and anti-patterns. Activate even when the user says 'add ads to my app', 'show a banner ad', 'monetize with AdMob', 'integrate Google ads', 'show a native ad', or 'display an interstitial' without explicitly mentioning AdConfig or AdService.
metadata:
  version: "1.1.0"
  last_modified: 2026-09-20
  min_flutter: "3.35"
  example_prompt: "Adicione um banner do AdMob com consentimento e IDs de teste"
---

# Implement AdMob — Flutter

## Leitura Rápida

- **AdService**: inicializa o SDK do Google Mobile Ads — chamado uma única vez no `AppInitializer`.
- **AdConfig**: centraliza todos os ad unit IDs separados por plataforma (Android/iOS) — NUNCA coloque IDs hardcoded fora desta classe.
- **InterstitialAdService**: gerencia o ciclo de vida de anúncios intersticiais — injete na View via DI, nunca no Cubit.
- **AdBannerWidget**: widget autogerenciado para banner ads — recebe apenas `adUnitId`, carrega e descarta sozinho.
- **AdNativeWidget**: widget autogerenciado para native ads — recebe `adUnitId` e `templateType`.
- **Quando exibir intersticial**: chame `load()` no `initState()` e `show()` depois que o conteúdo estiver visível;
  não use um atraso fixo como mecanismo de sincronização.
- **Registro no DI**: `AdService` e `InterstitialAdService` → `registerLazySingleton`.
- **Consentimento**: atualize UMP em cada abertura, mostre o formulário exigido e só peça anúncios quando
  `canRequestAds()` for verdadeiro.
- **ATT**: em iOS, configure `NSUserTrackingUsageDescription` e solicite autorização antes de rastreamento.
- **Debug**: use IDs oficiais de teste sempre que `kDebugMode` for verdadeiro; nunca arrisque tráfego real.
- **Nunca** passe `BuildContext` para os services de anúncio.
- **Nunca** chame `MobileAds.instance.initialize()` diretamente fora de `AdService`.

---

## Dependências (pubspec.yaml)

```yaml
dependencies:
  google_mobile_ads: ^9.1.0
```

Além da dependência, configure o App ID do Google Mobile Ads em `AndroidManifest.xml` e `Info.plist` conforme
o guia do SDK. App ID e ad unit ID são valores diferentes; não os troque.

## Workflow: adicionar um slot de anúncio

- [ ] 1. Definir formato, telas, frequência e comportamento quando o anúncio não carregar.
- [ ] 2. Adicionar `google_mobile_ads` e os App IDs por plataforma.
- [ ] 3. Configurar UMP/consentimento antes de `MobileAds.instance.initialize()`.
- [ ] 4. Configurar ATT e `NSUserTrackingUsageDescription` no iOS quando houver rastreamento.
- [ ] 5. Centralizar IDs reais e IDs de teste em `AdConfig`.
- [ ] 6. Implementar o Service/Widget com ciclo de vida e `dispose()` corretos.
- [ ] 7. Registrar no DI e inicializar uma única vez no bootstrap.
- [ ] 8. Testar serviço com dependências substituíveis e widget sem rede; não use anúncio real em teste.
- [ ] 9. Rodar `dart format --set-exit-if-changed lib test && flutter analyze --fatal-infos --fatal-warnings && flutter test`.
- [ ] 10. Listar os testes manuais: consentimento, anúncio indisponível, background/foreground e device físico.

---

## Estrutura de Arquivos

```
lib/
├── common/
│   ├── services/
│   │   └── ads/
│   │       ├── ad_config.dart              # IDs de anúncios por plataforma
│   │       ├── ad_service.dart             # Inicialização do SDK
│   │       └── interstitial_ad_service.dart # Gerenciamento de intersticiais
│   └── widgets/
│       ├── ad_banner_widget.dart           # Widget de banner
│       └── ad_native_widget.dart           # Widget nativo
```

---

## Inicialização (AppInitializer)

```dart
class AppInitializer {
  static Future<void> initialize(AppFlavor flavor) async {
    WidgetsFlutterBinding.ensureInitialized();
    await AppInjector.setupDependencies(flavor: flavor);

    // Inicializa o SDK de anúncios (sempre após setupDependencies)
    await AppInjector.inject.get<AdService>().initialize();
  }
}
```

---

## AdConfig — IDs Centralizados

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

abstract final class AdConfig {
  const AdConfig._();

  static String get banner {
    if (kDebugMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716425904';
    }
    if (Platform.isAndroid) return 'ca-app-pub-XXX/android-banner';
    if (Platform.isIOS) return 'ca-app-pub-XXX/ios-banner';
    throw UnsupportedError('Plataforma não suportada para anúncios');
  }

  static String get interstitial {
    if (kDebugMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    }
    if (Platform.isAndroid) return 'ca-app-pub-XXX/android-interstitial';
    if (Platform.isIOS) return 'ca-app-pub-XXX/ios-interstitial';
    throw UnsupportedError('Plataforma não suportada para anúncios');
  }

  static String get native {
    if (kDebugMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/2247696110';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/3986624511';
    }
    if (Platform.isAndroid) return 'ca-app-pub-XXX/android-native';
    if (Platform.isIOS) return 'ca-app-pub-XXX/ios-native';
    throw UnsupportedError('Plataforma não suportada para anúncios');
  }
}
```

**Regras:**
- ✅ SEMPRE use `Platform.isAndroid` / `Platform.isIOS` com IDs separados
- ✅ Em debug, use apenas IDs oficiais de teste; substitua os placeholders de produção antes do release
- ✅ Lance `UnsupportedError` para plataformas não suportadas
- ✅ Construtor privado `const AdConfig._()` — não instanciável
- ❌ NUNCA coloque IDs hardcoded fora de `AdConfig`
- ❌ Use `if` com `return` separados — não `if/else`

---

## AdService — Consentimento e inicialização do SDK

```dart
import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService({Future<bool> Function()? consentEvaluator})
      : _consentEvaluator = consentEvaluator;

  final Future<bool> Function()? _consentEvaluator;
  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    final canRequestAds = await (_consentEvaluator?.call() ?? _updateConsent());
    if (!canRequestAds) {
      log('AdService: ads blocked until consent is available');
      return;
    }

    await MobileAds.instance.initialize();
    _initialized = true;
    log('AdService: Google Mobile Ads initialized');
  }

  Future<bool> _updateConsent() {
    final completer = Completer<bool>();
    final params = ConsentRequestParameters(
      consentDebugSettings: kDebugMode
          ? const ConsentDebugSettings(
              testIdentifiers: ['TEST-DEVICE-HASHED-ID'],
            )
          : null,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((error) async {
          if (error != null) log('AdService: UMP form — $error');
          completer.complete(await ConsentInformation.instance.canRequestAds());
        });
      },
      (error) async {
        log('AdService: UMP update — $error');
        // A previous valid consent may still allow ads after a transient failure.
        completer.complete(await ConsentInformation.instance.canRequestAds());
      },
    );

    return completer.future;
  }
}
```

**Regras:**
- ✅ Guard `if (_initialized) return` para evitar inicialização dupla
- ✅ Chame `requestConsentInfoUpdate()` a cada abertura do app
- ✅ Chame `loadAndShowConsentFormIfRequired()` após atualizar o consentimento
- ✅ Verifique `canRequestAds()` antes de inicializar o SDK ou carregar um anúncio
- ✅ Remova `TEST-DEVICE-HASHED-ID` antes do release; use o identificador do dispositivo apenas em debug
- ✅ Use `log()` do `dart:developer` — nunca `print()`
- ✅ Registrar como `registerLazySingleton`

---

## InterstitialAdService — Anúncio Intersticial

```dart
import 'dart:developer';
import 'package:base_app/common/services/ads/ad_config.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdService {
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  bool get isReady => _interstitialAd != null;

  Future<void> load() async {
    if (_interstitialAd != null || _isLoading) return;
    _isLoading = true;

    await InterstitialAd.load(
      adUnitId: AdConfig.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          log('InterstitialAdService: ad loaded');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              load();  // Pré-carrega o próximo automaticamente
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              log('InterstitialAdService: failed to show — $error');
              ad.dispose();
              _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          log('InterstitialAdService: failed to load — $error');
        },
      ),
    );
  }

  void show() {
    if (_interstitialAd == null) {
      log('InterstitialAdService: ad not ready, loading...');
      load();
      return;
    }
    _interstitialAd!.show();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
```

**Regras:**
- ✅ Guard duplo no `load()`
- ✅ Pré-carrega o próximo no `onAdDismissedFullScreenContent`
- ✅ `show()` seguro: tenta recarregar se não estiver pronto
- ✅ Registrar como `registerLazySingleton`
- ❌ NUNCA passe `BuildContext` para este serviço
- ❌ NUNCA use no Cubit — apenas na View

---

## AdBannerWidget

```dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({
    required this.adUnitId,
    this.adSize = AdSize.banner,
    super.key,
  });

  final String adUnitId;
  final AdSize adSize;

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          log('AdBannerWidget: failed to load — $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return SizedBox(
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
```

---

## AdNativeWidget

```dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdNativeWidget extends StatefulWidget {
  const AdNativeWidget({
    required this.adUnitId,
    this.templateType = TemplateType.medium,
    super.key,
  });

  final String adUnitId;
  final TemplateType templateType;

  @override
  State<AdNativeWidget> createState() => _AdNativeWidgetState();
}

class _AdNativeWidgetState extends State<AdNativeWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: widget.adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          log('AdNativeWidget: failed to load — $error');
          ad.dispose();
          _nativeAd = null;
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(templateType: widget.templateType),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 320, minHeight: 90, maxHeight: 340),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
```

**Regras dos Widgets:**
- ✅ SEMPRE `StatefulWidget` com carregamento no `initState()`
- ✅ SEMPRE `dispose()` com `?.dispose()`
- ✅ SEMPRE verifique `if (mounted)` antes de `setState()`
- ✅ Retorne `SizedBox.shrink()` enquanto não carregado
- ✅ Receba `adUnitId` como parâmetro — nunca hardcoded
- ❌ NUNCA retorne placeholder visível (`Placeholder()`, `Container(color: Colors.grey)`)

---

## DI Registration

```dart
// Ads
inject.registerLazySingleton<AdService>(AdService.new);
inject.registerLazySingleton<InterstitialAdService>(InterstitialAdService.new);
```

---

## Uso nas Views

### Banner / Nativo

```dart
// Native ad
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: AdNativeWidget(adUnitId: AdConfig.native),
)

// Banner padrão
AdBannerWidget(adUnitId: AdConfig.banner)
```

### Intersticial

```dart
class _MyViewState extends State<MyView> {
  final _interstitialAdService = AppInjector.inject.get<InterstitialAdService>();

  @override
  void initState() {
    super.initState();
    _interstitialAdService.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _interstitialAdService.show();
    });
  }

  @override
  void dispose() {
    // NÃO chame _interstitialAdService.dispose() — é singleton
    super.dispose();
  }
}
```

**Regras de uso na View:**
- ✅ `load()` no `initState()` — pré-carrega
- ✅ `show()` depois do primeiro frame/conteúdo visível — nunca dentro de `build()`
- ✅ Verifique `mounted` antes de `show()`
- ❌ NUNCA chame `dispose()` do service na View — é singleton
- ❌ NUNCA exiba intersticial dentro de `build()`

---

## Fluxo de Decisão

```
Anúncio inline no conteúdo (lista, feed)?
  ├─ Layout integrado → AdNativeWidget (TemplateType.medium)
  └─ Banner compacto no rodapé → AdBannerWidget (AdSize.banner)

Anúncio de tela cheia ao abrir conteúdo?
  └─ InterstitialAdService: load() no initState + show() após o primeiro frame

Novo slot de anúncio?
  └─ Adicione getter estático em AdConfig com IDs Android + iOS
```

---

## Anti-Patterns

```dart
// ❌ IDs hardcoded fora do AdConfig
AdBannerWidget(adUnitId: 'ca-app-pub-XXX/YYY')

// ❌ Inicializar o SDK diretamente
await MobileAds.instance.initialize(); // fora de AdService

// ❌ Exibir intersticial dentro de build/initState sem o conteúdo visível
void initState() {
  super.initState();
  _adService.show(); // ERRADO: agende após o primeiro frame
}

// ❌ InterstitialAdService no Cubit
class MyCubit extends Cubit<MyState> {
  MyCubit(this._interstitialAdService); // ERRADO
}

// ❌ Chamar dispose() do singleton
void dispose() {
  _interstitialAdService.dispose(); // ERRADO
  super.dispose();
}
```

---

## Testes e conformidade

O Service precisa de uma costura substituível (`consentEvaluator`, gateway ou equivalente) para que o teste
não dependa de `MobileAds.instance`:

```dart
test('não inicializa anúncios quando consentimento não permite', () async {
  final service = AdService(consentEvaluator: () async => false);

  await service.initialize();

  expect(service.isInitialized, isFalse);
});
```

- [ ] UMP atualiza consentimento a cada abertura e só libera anúncios após `canRequestAds()`.
- [ ] IDs de teste são usados em debug/testes e removidos da configuração de release.
- [ ] iOS tem `NSUserTrackingUsageDescription` e ATT conforme o caso.
- [ ] `AdService`, loader e widgets podem ser testados sem rede real.
- [ ] `flutter analyze` e `flutter test` passam.

O usuário deve testar manualmente consentimento aceito/recusado, formulário de opções de privacidade,
falha de rede, background/foreground e anúncios em dispositivo físico.

**Última atualização**: 20 de setembro de 2026
