---
name: configure-di
description: Configures dependency injection (GetIt) for Flutter following the project architecture. Use whenever adding or modifying registrations in lib/config/inject/**. Covers registerFactory vs registerLazySingleton, registration order, multi-flavor setup, and common mistakes. Activate even when the user says 'register this class in the injector', 'how do I inject this dependency', 'GetIt is throwing an error', 'add this to AppInjector', 'should this be a singleton or factory?', 'I created a new service, where do I register it?', or 'dependency not found' without explicitly mentioning GetIt or registerLazySingleton.
---

# Configure DI (Dependency Injection) — Flutter

## Leitura Rápida

- **GetIt** é o único service locator: use `AppInjector.inject`.
- **Quando registrar um Cubit**: SEMPRE `registerFactory` — nunca singleton.
- **Quando registrar Service/Repository/DataSource/Dio**: SEMPRE `registerLazySingleton`.
- **Quando adicionar dependências**: siga a ordem — flavor → services → network → datasources → repositories → cubits.
- **Quando resolver dependência na View**: `AppInjector.inject.get<XCubit>()` e feche no `dispose()`.

---

## Estrutura

```
lib/config/
├── app_initializer.dart       # Inicialização central
└── inject/
    └── app_injector.dart      # Configuração de DI
```

---

## Template de AppInjector

```dart
import 'package:base_app/common/services/shared_preferences_service.dart';
import 'package:base_app/common/services/storage_service.dart';
import 'package:base_app/config/network/dio_client.dart';
import 'package:base_app/data/datasources/home_remote_datasource.dart';
import 'package:base_app/data/repositories/home_repository_impl.dart';
import 'package:base_app/domain/interfaces/home_repository.dart';
import 'package:base_app/presentation/home/view_model/home_cubit.dart';
import 'package:base_app/presentation/splash/view_model/splash_cubit.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

enum AppFlavor { development, staging, production }

class AppInjector {
  static GetIt inject = GetIt.instance;

  static Future<void> setupDependencies({required AppFlavor flavor}) async {
    // 1. Flavor
    inject.registerLazySingleton<AppFlavor>(() => flavor);

    final baseUrl = _getBaseUrlForFlavor(flavor);
    final enableLogs = flavor != AppFlavor.production;

    // 2. Services
    inject.registerLazySingleton<StorageService>(
      () => SharedPreferencesService(),
    );

    // 3. Network
    inject.registerLazySingleton<Dio>(
      () => makeDio(baseUrl: baseUrl, enableLogs: enableLogs),
    );

    // 4. DataSources
    inject.registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSource(inject()),
    );

    // 5. Repositories
    inject.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(inject()),
    );

    // 6. Cubits (SEMPRE Factory)
    inject.registerFactory<HomeCubit>(() => HomeCubit(inject()));
    inject.registerFactory<SplashCubit>(() => SplashCubit());
  }

  static String _getBaseUrlForFlavor(AppFlavor flavor) {
    return switch (flavor) {
      AppFlavor.development => 'https://dev-api.example.com',
      AppFlavor.staging => 'https://staging-api.example.com',
      AppFlavor.production => 'https://api.example.com',
    };
  }
}
```

---

## Tipos de Registro

### registerLazySingleton — Services, Repositories, DataSources, Network

```dart
// ✅ USE PARA:
inject.registerLazySingleton<StorageService>(() => SharedPreferencesService());
inject.registerLazySingleton<Dio>(() => makeDio(baseUrl: 'https://api.com'));
inject.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(inject()));
inject.registerLazySingleton<UserRemoteDataSource>(() => UserRemoteDataSource(inject()));
```

### registerFactory — Cubits (SEMPRE)

```dart
// ✅ USE PARA CUBITS:
inject.registerFactory<HomeCubit>(() => HomeCubit(inject()));
inject.registerFactory<ProfileCubit>(() => ProfileCubit(inject(), inject()));
```

---

## Adicionando uma Nova Feature (checklist)

### DataSource:
```dart
inject.registerLazySingleton<ProductRemoteDataSource>(
  () => ProductRemoteDataSource(inject()),
);
```

### Repository:
```dart
// 1. Interface em lib/domain/interfaces/
// 2. Implementação em lib/data/repositories/
inject.registerLazySingleton<ProductRepository>(
  () => ProductRepositoryImpl(inject()),
);
```

### Cubit:
```dart
inject.registerFactory<ProductsCubit>(
  () => ProductsCubit(inject()),
);
```

---

## Resolvendo na View

```dart
class _HomeViewState extends State<HomeView> {
  final _cubit = AppInjector.inject.get<HomeCubit>();

  @override
  void dispose() {
    _cubit.close();  // ✅ Sempre feche
    super.dispose();
  }
}
```

### Múltiplas Dependências

```dart
// No DI
inject.registerFactory<ProfileCubit>(
  () => ProfileCubit(
    inject<UserRepository>(),  // ✅ Especifica tipo
    inject<StorageService>(),
  ),
);
```

---

## Multi-Flavor Configuration

```dart
// Registro
inject.registerLazySingleton<AppFlavor>(() => flavor);

// Acesso em qualquer lugar
final flavor = AppInjector.inject<AppFlavor>();
if (flavor == AppFlavor.development) {
  log('Debug mode');
}
```

---

## Testando com DI

```dart
void main() {
  setUp(() {
    AppInjector.inject.reset();
  });

  test('should load home data', () async {
    final mockRepository = MockHomeRepository();
    AppInjector.inject.registerLazySingleton<HomeRepository>(() => mockRepository);
    final cubit = HomeCubit(AppInjector.inject<HomeRepository>());
    // ... teste
  });
}
```

---

## Checklist ao Adicionar Dependência

- [ ] Ordem correta: flavor → services → network → datasources → repositories → cubits
- [ ] Cubits com `registerFactory`, resto com `registerLazySingleton`
- [ ] Tipo explícito ao resolver: `inject<UserRepository>()`
- [ ] Cubit fechado no `dispose()` da View

---

## Erros Comuns

| Erro | Correto |
|---|---|
| `registerLazySingleton<HomeCubit>(...)` | `registerFactory<HomeCubit>(...)` |
| `inject.get()` sem tipo | `inject.get<HomeCubit>()` |
| Cubit registrado antes do Repository | Registre dependências ANTES de quem as usa |
| Não chamar `_cubit.close()` no dispose | Sempre feche o Cubit no `dispose()` |

---

**Resumo das regras de ouro:**
- ✅ Cubits são **sempre** Factory
- ✅ Repositories são **sempre** LazySingleton
- ✅ Registre dependências **antes** de usá-las
- ✅ Especifique **tipo explícito** ao resolver
- ✅ Feche Cubits no `dispose()`

---

**Última atualização**: 28 de março de 2026
