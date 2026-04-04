---
name: implement-admob
description: Implements Google AdMob ads (banner, native, interstitial) in Flutter following the project architecture. Use whenever adding or modifying ad-related files, integrating the AdMob SDK, adding monetization via ads, creating banner or native ad widgets, managing interstitial ad lifecycle, or centralizing ad unit IDs. Covers AdConfig centralized IDs, AdService SDK init, InterstitialAdService lifecycle, AdBannerWidget, AdNativeWidget, DI registration, and anti-patterns. Activate even when the user says 'add ads to my app', 'show a banner ad', 'monetize with AdMob', 'integrate Google ads', 'show a native ad', or 'display an interstitial' without explicitly mentioning AdConfig or AdService.
---

# Implement AdMob — Flutter

## Leitura Rápida

- **AdService**: inicializa o SDK do Google Mobile Ads — chamado uma única vez no `AppInitializer`.
- **AdConfig**: centraliza todos os ad unit IDs separados por plataforma (Android/iOS) — NUNCA coloque IDs hardcoded fora desta classe.
- **InterstitialAdService**: gerencia o ciclo de vida de anúncios intersticiais — injete na View via DI, nunca no Cubit.
- **AdBannerWidget**: widget autogerenciado para banner ads — recebe apenas `adUnitId`, carrega e descarta sozinho.
- **AdNativeWidget**: widget autogerenciado para native ads — recebe `adUnitId` e `templateType`.
- **Quando exibir intersticial**: chame `load()` no `initState()` e `show()` com `Future.delayed` após o conteúdo estar visível.
- **Registro no DI**: `AdService` e `InterstitialAdService` → `registerLazySingleton`.
- **Nunca** passe `BuildContext` para os services de anúncio.
- **Nunca** chame `MobileAds.instance.initialize()` diretamente fora de `AdService`.

---

## Dependências (pubspec.yaml)

```yaml
dependencies:
  google_mobile_ads: ^5.x.x
```

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

class AdConfig {
  const AdConfig._();

  static String get nativeBanner1 {
    if (Platform.isAndroid) return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    if (Platform.isIOS) return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    throw UnsupportedError('Plataforma não suportada para anúncios');
  }

  static String get banner2 {
    if (Platform.isAndroid) return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    if (Platform.isIOS) return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    throw UnsupportedError('Plataforma não suportada para anúncios');
  }

  static String get interstitial {
    if (Platform.isAndroid) return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    if (Platform.isIOS) return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    throw UnsupportedError('Plataforma não suportada para anúncios');
  }
}
```

**Regras:**
- ✅ SEMPRE use `Platform.isAndroid` / `Platform.isIOS` com IDs separados
- ✅ Lance `UnsupportedError` para plataformas não suportadas
- ✅ Construtor privado `const AdConfig._()` — não instanciável
- ❌ NUNCA coloque IDs hardcoded fora de `AdConfig`
- ❌ Use `if` com `return` separados — não `if/else`

---

## AdService — Inicialização do SDK

```dart
import 'dart:developer';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    log('AdService: Google Mobile Ads initialized');
  }
}
```

**Regras:**
- ✅ Guard `if (_initialized) return` para evitar inicialização dupla
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
  child: AdNativeWidget(adUnitId: AdConfig.nativeBanner1),
)

// Banner padrão
AdBannerWidget(adUnitId: AdConfig.banner2)
```

### Intersticial

```dart
class _MyViewState extends State<MyView> {
  final _interstitialAdService = AppInjector.inject.get<InterstitialAdService>();

  @override
  void initState() {
    super.initState();
    _interstitialAdService.load();
    Future.delayed(const Duration(seconds: 3), () {
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
- ✅ `show()` com `Future.delayed` — nunca imediatamente
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
  └─ InterstitialAdService: load() no initState + show() com delay

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

// ❌ Exibir intersticial sem delay
void initState() {
  super.initState();
  _adService.show(); // ERRADO
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

**Última atualização**: 28 de março de 2026
