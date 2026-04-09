---
name: implement-service
description: Implements Common Services in common/services/ following the project architecture. Use whenever creating or modifying a service that abstracts device/platform resources — storage flags, feature gating, one-time actions, onboarding control, premium access checks, usage counters, biometric auth, or any local logic that doesn't belong in a Repository. Covers abstract interface + concrete implementation, StorageService delegation, DI registration as LazySingleton, and injection into Cubits. Activate even when the user says 'only allow one click', 'show onboarding once', 'check if user is premium', 'save a flag locally', 'create a service for X', 'where do I put this logic', 'gate this feature behind premium', 'track how many times the user did X', 'remember that the user already saw this', or 'limit usage without backend' without explicitly mentioning StorageService, SharedPreferences, or common/services.
---

# Implement Common Service — Flutter

Implementa Services em `common/services/` seguindo a arquitetura do projeto.

## Leitura Rápida

- **Service vs Repository**: Service abstrai recurso do dispositivo/plataforma (storage, biometria, flags, contadores). Repository abstrai API externa com Entity. Se não há API, não crie Repository.
- **Interface obrigatória**: SEMPRE crie uma classe abstrata + implementação concreta separada.
- **StorageService**: toda lógica de `SharedPreferences` DEVE passar pelo `StorageService` — NUNCA acesse `SharedPreferences` diretamente.
- **DI**: Services → `registerLazySingleton`; NUNCA `registerFactory`.
- **Cubit**: injete o Service via construtor — sem intermediário Repository.
- **Chaves de storage**: use constantes `static const` dentro do Service — nunca string literals espalhadas.
- **View**: NUNCA acesse um Service diretamente da View — sempre passe pelo Cubit.
- **Lógica**: toda lógica de negócio local (flags, contadores, gating) fica no Service, não no Cubit.

---

## Quando criar um novo Service?

| Situação | Solução |
|---|---|
| Persistir preferências, flags ou tokens | `StorageService` (já existe) |
| Controlar onboarding, primeiro acesso, ação única | Novo Service que usa `StorageService` |
| Gating de feature (premium, limite de uso) | Novo Service que usa `StorageService` |
| Contadores de uso (ex: máx. 3 cliques grátis) | Novo Service que usa `StorageService` |
| Biometria, câmera, notificações, localização | Novo Service com SDK da plataforma |
| Dados de API externa com Entity | **Repository** (não Service) |

**Regra geral**: se a lógica é local ao dispositivo e não envolve rede, é um Service. Se envolve rede e retorna Entity, é um Repository.

---

## Estrutura de Pastas

```
lib/common/services/
├── storage_service.dart                    # Interface abstrata (já existente)
├── shared_preferences_service.dart         # Implementação concreta (já existente)
├── feature_gate/
│   ├── feature_gate_service.dart           # Interface abstrata
│   └── feature_gate_service_impl.dart      # Implementação concreta
├── onboarding/
│   ├── onboarding_service.dart             # Interface abstrata
│   └── onboarding_service_impl.dart        # Implementação concreta
└── <nome_do_service>/
    ├── <nome>_service.dart                 # Interface
    └── <nome>_service_impl.dart            # Implementação
```

**Convenção**: se o Service é simples (1 arquivo), pode ficar direto em `common/services/`. Se tem lógica significativa, crie uma subpasta.

---

## Passo 1 — Perguntas ao usuário

Antes de gerar código, entenda o cenário:

```
1. O que o Service precisa controlar?
   Ex: "mostrar onboarding só uma vez", "limitar 3 usos grátis",
       "lembrar se já viu a tela X"

2. A lógica depende apenas de dados locais (SharedPreferences)
   ou de algum recurso do dispositivo (biometria, câmera, etc.)?

3. Esse controle precisa ser resetável pelo usuário?
   (ex: resetar contador, refazer onboarding)

4. Qual feature/tela vai consumir esse Service?
```

---

## Passo 2 — Criar a Interface Abstrata

A interface define o contrato. O Cubit e os testes dependem apenas dela.

```dart
abstract class OnboardingService {
  /// Retorna true se o onboarding já foi concluído
  Future<bool> isOnboardingCompleted();

  /// Marca o onboarding como concluído
  Future<void> completeOnboarding();

  /// Reseta o estado do onboarding (útil para debug/testes)
  Future<void> resetOnboarding();
}
```

**Regras da interface:**
- `abstract class` (não `abstract interface class` para manter consistência com o projeto)
- Métodos retornam `Future<T>` quando envolvem storage
- Sem imports de infra — apenas tipos Dart nativos ou Entities do domínio
- Sem implementação — apenas assinaturas

---

## Passo 3 — Criar a Implementação Concreta

A implementação recebe `StorageService` via construtor e encapsula toda a lógica.

### Template: Service com Flag (ação única)

```dart
import 'package:base_app/common/services/onboarding/onboarding_service.dart';
import 'package:base_app/common/services/storage_service.dart';

class OnboardingServiceImpl implements OnboardingService {
  const OnboardingServiceImpl(this._storage);

  final StorageService _storage;

  static const _keyOnboardingCompleted = 'onboarding_completed';

  @override
  Future<bool> isOnboardingCompleted() async {
    return await _storage.getBool(_keyOnboardingCompleted) ?? false;
  }

  @override
  Future<void> completeOnboarding() async {
    await _storage.setBool(_keyOnboardingCompleted, true);
  }

  @override
  Future<void> resetOnboarding() async {
    await _storage.remove(_keyOnboardingCompleted);
  }
}
```

### Template: Service com Contador (limite de uso)

```dart
import 'package:base_app/common/services/feature_gate/feature_gate_service.dart';
import 'package:base_app/common/services/storage_service.dart';

class FeatureGateServiceImpl implements FeatureGateService {
  const FeatureGateServiceImpl(this._storage);

  final StorageService _storage;

  static const _keyUsageCount = 'feature_usage_count';
  static const _maxFreeUsage = 3;

  @override
  Future<bool> canUseFeature() async {
    final count = await _storage.getInt(_keyUsageCount) ?? 0;
    return count < _maxFreeUsage;
  }

  @override
  Future<int> getRemainingUsage() async {
    final count = await _storage.getInt(_keyUsageCount) ?? 0;
    final remaining = _maxFreeUsage - count;
    return remaining > 0 ? remaining : 0;
  }

  @override
  Future<void> recordUsage() async {
    final count = await _storage.getInt(_keyUsageCount) ?? 0;
    await _storage.setInt(_keyUsageCount, count + 1);
  }

  @override
  Future<void> resetUsage() async {
    await _storage.remove(_keyUsageCount);
  }
}
```

### Template: Service com Premium Check

Quando o app tem compras in-app, o service precisa verificar se o usuário desbloqueou o acesso premium. O dado de compra já está salvo via `StorageService` (veja skill `implement-in-app-purchase`).

```dart
import 'package:base_app/common/services/premium/premium_service.dart';
import 'package:base_app/common/services/storage_service.dart';

class PremiumServiceImpl implements PremiumService {
  const PremiumServiceImpl(this._storage);

  final StorageService _storage;

  static const _keyPremiumUnlocked = 'premium_unlocked';

  @override
  Future<bool> isPremium() async {
    return await _storage.getBool(_keyPremiumUnlocked) ?? false;
  }

  @override
  Future<void> unlockPremium() async {
    await _storage.setBool(_keyPremiumUnlocked, true);
  }

  @override
  Future<void> revokePremium() async {
    await _storage.setBool(_keyPremiumUnlocked, false);
  }
}
```

### Template: Service com Flag + Contador Combinados (gating composto)

Para cenários onde o acesso gratuito tem limite e depois exige premium:

```dart
import 'package:base_app/common/services/premium/premium_service.dart';
import 'package:base_app/common/services/storage_service.dart';

class GatedFeatureServiceImpl implements GatedFeatureService {
  const GatedFeatureServiceImpl(
    this._storage,
    this._premiumService,
  );

  final StorageService _storage;
  final PremiumService _premiumService;

  static const _keyUsageCount = 'gated_feature_usage';
  static const _maxFreeUsage = 3;

  @override
  Future<bool> canAccess() async {
    final isPremium = await _premiumService.isPremium();
    if (isPremium) return true;

    final count = await _storage.getInt(_keyUsageCount) ?? 0;
    return count < _maxFreeUsage;
  }

  @override
  Future<void> recordAccess() async {
    final isPremium = await _premiumService.isPremium();
    if (isPremium) return;

    final count = await _storage.getInt(_keyUsageCount) ?? 0;
    await _storage.setInt(_keyUsageCount, count + 1);
  }

  @override
  Future<int> remainingFreeAccess() async {
    final count = await _storage.getInt(_keyUsageCount) ?? 0;
    final remaining = _maxFreeUsage - count;
    return remaining > 0 ? remaining : 0;
  }
}
```

### Template: Service com Timestamp (mostrar uma vez por período)

Para cenários como "mostrar review popup a cada 30 dias":

```dart
import 'package:base_app/common/services/review_prompt/review_prompt_service.dart';
import 'package:base_app/common/services/storage_service.dart';

class ReviewPromptServiceImpl implements ReviewPromptService {
  const ReviewPromptServiceImpl(this._storage);

  final StorageService _storage;

  static const _keyLastShown = 'review_prompt_last_shown';
  static const _intervalDays = 30;

  @override
  Future<bool> shouldShowPrompt() async {
    final lastShown = await _storage.getString(_keyLastShown);
    if (lastShown == null) return true;

    final lastDate = DateTime.tryParse(lastShown);
    if (lastDate == null) return true;

    final daysSince = DateTime.now().difference(lastDate).inDays;
    return daysSince >= _intervalDays;
  }

  @override
  Future<void> markPromptShown() async {
    await _storage.setString(
      _keyLastShown,
      DateTime.now().toIso8601String(),
    );
  }
}
```

---

## Passo 4 — Registrar no DI

```dart
// Em app_injector.dart — seção 2 (Services)

// StorageService já existente
inject.registerLazySingleton<StorageService>(
  () => SharedPreferencesService(),
);

// Novos services — SEMPRE LazySingleton
inject.registerLazySingleton<OnboardingService>(
  () => OnboardingServiceImpl(inject()),
);

inject.registerLazySingleton<FeatureGateService>(
  () => FeatureGateServiceImpl(inject()),
);

inject.registerLazySingleton<PremiumService>(
  () => PremiumServiceImpl(inject()),
);

// Service composto (depende de outro Service)
inject.registerLazySingleton<GatedFeatureService>(
  () => GatedFeatureServiceImpl(inject(), inject()),
);
```

**Ordem de registro**: Services que dependem de outros Services DEVEM ser registrados depois das dependências. O `registerLazySingleton` resolve isso naturalmente (instância criada no primeiro `get()`), mas manter a ordem correta torna o código legível.

---

## Passo 5 — Usar no Cubit

O Cubit recebe o Service via construtor e delega a lógica de negócio local a ele.

### Padrão: Verificar flag antes de ação

```dart
import 'package:base_app/common/services/feature_gate/feature_gate_service.dart';
import 'package:base_app/presentation/generator/view_model/generator_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GeneratorCubit extends Cubit<GeneratorState> {
  GeneratorCubit(this._featureGateService)
      : super(const GeneratorInitial());

  final FeatureGateService _featureGateService;

  Future<void> generate() async {
    emit(const GeneratorLoading());

    final canUse = await _featureGateService.canAccess();
    if (!canUse) {
      emit(const GeneratorPremiumRequired());
      return;
    }

    await _featureGateService.recordAccess();
    // ... lógica de geração ...
    emit(const GeneratorSuccess(result: '...'));
  }

  Future<void> checkAccess() async {
    final canUse = await _featureGateService.canAccess();
    final remaining = await _featureGateService.remainingFreeAccess();
    emit(GeneratorAccessInfo(
      canUse: canUse,
      remainingFree: remaining,
    ));
  }
}
```

### Padrão: Onboarding no Splash/Home

```dart
class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._onboardingService)
      : super(const SplashInitial());

  final OnboardingService _onboardingService;

  Future<void> checkInitialRoute() async {
    final onboardingDone =
        await _onboardingService.isOnboardingCompleted();

    if (!onboardingDone) {
      emit(const SplashNavigateToOnboarding());
    } else {
      emit(const SplashNavigateToHome());
    }
  }
}
```

### Padrão: Marcar ação como concluída (click once)

```dart
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._onboardingService)
      : super(const OnboardingInitial());

  final OnboardingService _onboardingService;

  Future<void> finishOnboarding() async {
    await _onboardingService.completeOnboarding();
    emit(const OnboardingNavigateToHome());
  }
}
```

**Registro do Cubit no DI:**
```dart
inject.registerFactory<GeneratorCubit>(
  () => GeneratorCubit(inject()),
);
inject.registerFactory<SplashCubit>(
  () => SplashCubit(inject()),
);
```

---

## Padrões Comuns com States

### State com gating (premium required)

```dart
@immutable
sealed class GeneratorState { const GeneratorState(); }

class GeneratorInitial extends GeneratorState {
  const GeneratorInitial();
}

class GeneratorLoading extends GeneratorState {
  const GeneratorLoading();
}

class GeneratorSuccess extends GeneratorState {
  const GeneratorSuccess({required this.result});
  final String result;
}

class GeneratorPremiumRequired extends GeneratorState {
  const GeneratorPremiumRequired();
}

class GeneratorAccessInfo extends GeneratorState {
  const GeneratorAccessInfo({
    required this.canUse,
    required this.remainingFree,
  });
  final bool canUse;
  final int remainingFree;
}

class GeneratorError extends GeneratorState {
  const GeneratorError(this.message);
  final String message;
}
```

### View reagindo ao gating

```dart
BlocBuilder<GeneratorCubit, GeneratorState>(
  bloc: _cubit,
  builder: (context, state) => switch (state) {
    GeneratorInitial() => const SizedBox.shrink(),
    GeneratorLoading() =>
      const Center(child: CircularProgressIndicator()),
    GeneratorSuccess(:final result) => Text(result),
    GeneratorPremiumRequired() => PremiumRequiredContent(
      onUpgrade: () => context.push(AppRoutes.purchase),
    ),
    GeneratorAccessInfo(:final remainingFree) =>
      Text(context.l10n.remainingFreeUses(remainingFree)),
    GeneratorError(:final message) => Text(message),
  },
)
```

---

## Checklist

### Interface:
- [ ] Arquivo em `lib/common/services/<nome>/<nome>_service.dart`
- [ ] `abstract class` com métodos `Future<T>`
- [ ] Sem imports de infra — apenas tipos Dart ou Entities

### Implementação:
- [ ] Arquivo em `lib/common/services/<nome>/<nome>_service_impl.dart`
- [ ] `implements` a interface abstrata
- [ ] `StorageService` recebido via construtor
- [ ] Chaves de storage como `static const` dentro da classe
- [ ] `const` no construtor
- [ ] Toda lógica de negócio local encapsulada — Cubit apenas chama métodos
- [ ] Imports absolutos com `package:base_app/...`

### DI:
- [ ] `registerLazySingleton` (NUNCA factory)
- [ ] Registrado na seção 2 (Services) do `app_injector.dart`
- [ ] Dependências do Service registradas antes dele

### Cubit:
- [ ] Recebe o Service via construtor (interface, não implementação)
- [ ] `registerFactory` para o Cubit
- [ ] Verifica o Service ANTES de executar ação gated
- [ ] States incluem caso de gating (`PremiumRequired`, `LimitReached`, etc.)

---

## Anti-patterns a evitar

- ❌ NÃO acesse `SharedPreferences` diretamente — use `StorageService`
- ❌ NÃO crie Repository para lógica puramente local — use Service
- ❌ NÃO espalhe chaves de storage como strings literais — centralize como `static const` no Service
- ❌ NÃO coloque lógica de gating/flags/contadores no Cubit — encapsule no Service
- ❌ NÃO acesse Service diretamente da View — passe pelo Cubit
- ❌ NÃO registre Service como `registerFactory` — use `registerLazySingleton`
- ❌ NÃO crie Service sem interface abstrata — sempre separe contrato de implementação
- ❌ NÃO use `StorageService` dentro de um Repository — Repository é para API externa
- ❌ NÃO passe `BuildContext` ao Service
- ❌ NÃO crie múltiplas instâncias de Service que controlam o mesmo dado — centralize em um único Service

---

**Última atualização**: 07 de abril de 2026
