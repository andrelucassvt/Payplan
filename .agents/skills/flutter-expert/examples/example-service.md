# Exemplo: Common Services

Cenário: onboarding (mostrar uma vez), feature gate (limite de uso), e premium.

**Referências**: `service.md`, `view-model.md`, `di.md`

---

## Padrão 1 — Onboarding (flag única)

### Interface

```dart
// lib/common/services/onboarding/onboarding_service.dart
abstract class OnboardingService {
  Future<bool> isCompleted();
  Future<void> complete();
  Future<void> reset();
}
```

### Implementação

```dart
// lib/common/services/onboarding/onboarding_service_impl.dart
import 'package:base_app/common/services/onboarding/onboarding_service.dart';
import 'package:base_app/common/services/storage_service.dart';

class OnboardingServiceImpl implements OnboardingService {
  const OnboardingServiceImpl(this._storage);

  final StorageService _storage;

  static const _key = 'onboarding_completed';

  @override
  Future<bool> isCompleted() async =>
      await _storage.getBool(_key) ?? false;

  @override
  Future<void> complete() => _storage.setBool(_key, true);

  @override
  Future<void> reset() => _storage.remove(_key);
}
```

### Cubit que consome o Service

```dart
// lib/presentation/splash/view_model/splash_cubit.dart
import 'package:base_app/common/services/onboarding/onboarding_service.dart';
import 'package:base_app/presentation/splash/view_model/splash_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._onboarding) : super(const SplashInitial());

  final OnboardingService _onboarding;

  Future<void> checkInitialRoute() async {
    final done = await _onboarding.isCompleted();
    emit(done ? const SplashNavigateToHome() : const SplashNavigateToOnboarding());
  }
}
```

### States

```dart
@immutable
sealed class SplashState { const SplashState(); }

class SplashInitial extends SplashState { const SplashInitial(); }
class SplashNavigateToHome extends SplashState { const SplashNavigateToHome(); }
class SplashNavigateToOnboarding extends SplashState { const SplashNavigateToOnboarding(); }
```

### DI

```dart
inject.registerLazySingleton<OnboardingService>(
  () => OnboardingServiceImpl(inject()),
);
inject.registerFactory<SplashCubit>(() => SplashCubit(inject()));
```

---

## Padrão 2 — Feature Gate (limite de 3 usos gratuitos)

### Interface

```dart
// lib/common/services/feature_gate/feature_gate_service.dart
abstract class FeatureGateService {
  Future<bool> canUse();
  Future<int> remaining();
  Future<void> recordUse();
  Future<void> reset();
}
```

### Implementação

```dart
// lib/common/services/feature_gate/feature_gate_service_impl.dart
import 'package:base_app/common/services/feature_gate/feature_gate_service.dart';
import 'package:base_app/common/services/storage_service.dart';

class FeatureGateServiceImpl implements FeatureGateService {
  const FeatureGateServiceImpl(this._storage);

  final StorageService _storage;

  static const _key = 'feature_usage_count';
  static const _limit = 3;

  @override
  Future<bool> canUse() async {
    final count = await _storage.getInt(_key) ?? 0;
    return count < _limit;
  }

  @override
  Future<int> remaining() async {
    final count = await _storage.getInt(_key) ?? 0;
    final r = _limit - count;
    return r > 0 ? r : 0;
  }

  @override
  Future<void> recordUse() async {
    final count = await _storage.getInt(_key) ?? 0;
    await _storage.setInt(_key, count + 1);
  }

  @override
  Future<void> reset() => _storage.remove(_key);
}
```

### States com gating

```dart
@immutable
sealed class GeneratorState { const GeneratorState(); }

class GeneratorInitial extends GeneratorState { const GeneratorInitial(); }
class GeneratorLoading extends GeneratorState { const GeneratorLoading(); }
class GeneratorSuccess extends GeneratorState {
  const GeneratorSuccess({required this.result});
  final String result;
}
class GeneratorPremiumRequired extends GeneratorState { const GeneratorPremiumRequired(); }
class GeneratorAccessInfo extends GeneratorState {
  const GeneratorAccessInfo({required this.canUse, required this.remaining});
  final bool canUse;
  final int remaining;
}
class GeneratorError extends GeneratorState {
  const GeneratorError(this.message);
  final String message;
}
```

### Cubit com gate check

```dart
class GeneratorCubit extends Cubit<GeneratorState> {
  GeneratorCubit(this._gate) : super(const GeneratorInitial());

  final FeatureGateService _gate;

  Future<void> checkAccess() async {
    final canUse = await _gate.canUse();
    final remaining = await _gate.remaining();
    emit(GeneratorAccessInfo(canUse: canUse, remaining: remaining));
  }

  Future<void> generate() async {
    emit(const GeneratorLoading());

    if (!await _gate.canUse()) {
      emit(const GeneratorPremiumRequired());
      return;
    }

    await _gate.recordUse();
    // ... lógica real de geração
    emit(const GeneratorSuccess(result: 'resultado gerado'));
  }
}
```

### View reagindo ao gating

```dart
BlocBuilder<GeneratorCubit, GeneratorState>(
  builder: (context, state) => switch (state) {
    GeneratorInitial() => const SizedBox.shrink(),
    GeneratorLoading() => const Center(child: CircularProgressIndicator()),
    GeneratorSuccess(:final result) => Text(result),
    GeneratorPremiumRequired() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.premiumRequiredMessage),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.purchase),
              child: Text(context.l10n.upgradeButton),
            ),
          ],
        ),
      ),
    GeneratorAccessInfo(:final remaining) =>
      Text(context.l10n.remainingFreeUses(remaining)),
    GeneratorError(:final message) => Text(message),
  },
)
```

### DI

```dart
inject.registerLazySingleton<FeatureGateService>(
  () => FeatureGateServiceImpl(inject()),
);
inject.registerFactory<GeneratorCubit>(() => GeneratorCubit(inject()));
```

---

## Padrão 3 — Review Prompt (mostrar a cada 30 dias)

### Interface

```dart
abstract class ReviewPromptService {
  Future<bool> shouldShow();
  Future<void> markShown();
}
```

### Implementação

```dart
class ReviewPromptServiceImpl implements ReviewPromptService {
  const ReviewPromptServiceImpl(this._storage);

  final StorageService _storage;

  static const _key = 'review_last_shown';
  static const _intervalDays = 30;

  @override
  Future<bool> shouldShow() async {
    final raw = await _storage.getString(_key);
    if (raw == null) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    return DateTime.now().difference(last).inDays >= _intervalDays;
  }

  @override
  Future<void> markShown() =>
      _storage.setString(_key, DateTime.now().toIso8601String());
}
```

---

## Regras Resumidas

| Regra | Correto |
|---|---|
| Acesso a `SharedPreferences` | Sempre via `StorageService` |
| Chaves de storage | `static const` dentro do Service |
| Registro no DI | `registerLazySingleton` (nunca `registerFactory`) |
| Lógica de gating/flags/contadores | No Service, não no Cubit |
| Acesso pelo Cubit | Interface, não a implementação concreta |
