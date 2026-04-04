---
applyTo: '**'
---

# Instruções de Arquitetura - Base App Flutter

---

## ✅ Regras-Chave para IA (leia sempre primeiro)

- **Prioridade**: este documento vence qualquer conflito com outros arquivos de instrução.
- **Nova feature**: comece com o mínimo — View + Cubit + State + rota + DI. Use o `🧭 Fluxo de Decisão` abaixo.
- **Cubit async**: SEMPRE emita `Loading` primeiro → chame o repository → use `result.when()`.
- **Textos na UI**: SEMPRE `context.l10n.<chave>` — nunca string hardcoded.
- **Navegação**: SEMPRE na View (ou `BlocListener`) — nunca passe `BuildContext` ao Cubit.
- **Repository error**: SEMPRE envolva em `try/catch` e retorne `Result.error(...)`.
- **Entity**: SEMPRE `@immutable`, `const`, `final`, `copyWith()`, `==`, `hashCode`.
- **DI**: Cubits → `registerFactory`; tudo mais → `registerLazySingleton`.
- **Dependências**: `presentation` → usa `domain`; `data` → implementa `domain`; `domain` → nada externo.
- **View performance**: NUNCA crie `Widget _buildXxx()` nem classes privadas de widget na View — extraia para `widgets/` (reutilizável) ou `content/` (auxiliar específico). Dialog/bottomSheet são exceção.
- **SafeArea**: SEMPRE envolva o conteúdo principal da View com `SafeArea`.
- **Imports**: SEMPRE absolutos com `package:base_app/...` — NUNCA relativos.
- **Storage**: NUNCA acesse `SharedPreferences` direto no Cubit — use `StorageService`.
- **Arquivos .md**: NUNCA crie arquivos `.md` para documentar mudanças de código.

---

## 🏗️ Arquitetura

```
┌─────────────────┐
│  Presentation   │ ← Views (UI) + Cubits (BLoC)
├─────────────────┤
│     Domain      │ ← Entities + Interfaces (Contratos)
├─────────────────┤
│      Data       │ ← Models + DataSources + Repositories
└─────────────────┘
```

Fluxo de dependências: `Presentation → Domain ← Data`

---

## 📂 Estrutura de Pastas (OBRIGATÓRIA)

```
lib/
├── presentation/
│   └── <feature>/
│       ├── view/<feature>_view.dart
│       ├── view_model/<feature>_cubit.dart
│       ├── view_model/<feature>_state.dart
│       ├── widgets/          # widgets reutilizáveis da feature
│       ├── content/          # auxiliares de UI específicos (não reutilizáveis)
│       └── utils/            # formatters/validators específicos
│
├── domain/
│   ├── entities/<entity>_entity.dart
│   └── interfaces/<feature>_repository.dart
│
├── data/
│   ├── models/<entity>_model.dart
│   ├── datasources/<feature>_remote_datasource.dart
│   └── repositories/<feature>_repository_impl.dart
│
├── common/
│   ├── widgets/
│   ├── styles/
│   ├── utils/
│   ├── services/             # StorageService, BiometricService, etc.
│   └── errors/
│
├── config/
│   ├── error/result_pattern.dart
│   ├── routes/app_router.dart + app_routes.dart
│   ├── network/dio_client.dart + auth_interceptor.dart
│   ├── inject/app_injector.dart
│   └── app_initializer.dart
│
└── l10n/
```

**Proibido:**
- Criar widgets fora de `presentation/` (exceto `common/widgets/`)
- Acessar DataSources diretamente do Cubit
- Importar classes de `data/` dentro de `domain/`
- Criar arquivos barrel/export

---

## 🧭 Fluxo de Decisão: o que criar em uma nova feature?

```
Feature precisa de API ou banco externo?
  ├─ SIM → criar Data Layer:
  │         Entity + Repository Interface + Model + DataSource + RepositoryImpl
  │         + registrar DataSource e Repository no AppInjector
  │
  └─ NÃO ─ precisa persistir dados localmente?
              ├─ SIM → injetar StorageService no Cubit (sem Data Layer)
              └─ NÃO → apenas View + Cubit + State + rota + DI
```

| Situação | O que criar |
|---|---|
| Tela simples / UI local | View + Cubit + State + rota + DI |
| Dados locais | + `StorageService` no Cubit |
| API externa | + Entity + Repository Interface + Model + DataSource + RepositoryImpl |
| Widget reutilizável na feature | `presentation/<feature>/widgets/` |
| Widget reutilizável entre features | `common/widgets/` |
| Auxiliar de UI específico de uma View | `presentation/<feature>/content/` |
| Compras in-app | skill `implement-in-app-purchase` — sem Repository |

---

## 🧩 Padrões por Camada

### View (StatefulWidget)

```dart
class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final _cubit = AppInjector.inject.get<HomeCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.loadHome();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.homeTitle)),
        body: BlocBuilder<HomeCubit, HomeState>(
          bloc: _cubit,
          builder: (context, state) => switch (state) {
            HomeLoading() => const Center(child: CircularProgressIndicator()),
            HomeLoaded(:final message) => Text(message),
            HomeError(:final message) => Text(message),
            HomeInitial() => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}
```

**Regras:** obtém Cubit via DI; usa `BlocBuilder`; chama `_cubit.close()` no `dispose()`; usa `initState()` para carregar dados; sem lógica de negócio.

---

### Cubit

```dart
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._homeRepository) : super(const HomeInitial());
  final HomeRepository _homeRepository;

  Future<void> loadHome() async {
    emit(const HomeLoading());
    final result = await _homeRepository.loadHomeData();
    result.when(
      ok: (data) => emit(HomeLoaded(message: data.message)),
      error: (e) => emit(HomeError('Erro ao carregar: $e')),
    );
  }
}
```

**Regras:** dependências via construtor; emite Loading antes de async; usa `result.when()`; sem lógica de UI; sem acesso direto a DataSources.

---

### State (Sealed Classes)

```dart
@immutable
sealed class HomeState { const HomeState(); }

class HomeInitial extends HomeState { const HomeInitial(); }
class HomeLoading extends HomeState { const HomeLoading(); }
class HomeLoaded extends HomeState {
  const HomeLoaded({required this.message});
  final String message;
}
class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
}
```

**Regras:** `sealed class` + `@immutable` + `const`; propriedades `final`; sem métodos.

---

### Entity

```dart
@immutable
class HomeEntity {
  const HomeEntity({required this.message, required this.items});
  final String message;
  final List<String> items;

  HomeEntity copyWith({String? message, List<String>? items}) =>
      HomeEntity(message: message ?? this.message, items: items ?? this.items);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeEntity && message == other.message && listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(message, items);
}
```

**Regras:** `@immutable`, `copyWith()`, `==`, `hashCode`; sem imports de infra; sem serialização.

---

### Repository Interface (domain)

```dart
abstract class HomeRepository {
  Future<Result<HomeEntity>> loadHomeData();
}
```

**Regras:** apenas contratos; retorna `Result<T>`; usa Entities; sem implementações.

---

### Model (data)

```dart
class HomeModel extends HomeEntity {
  const HomeModel({required super.message, required super.items});

  factory HomeModel.fromJson(Map<String, dynamic> json) => HomeModel(
    message: json['message'] as String? ?? '',
    items: (json['items'] as List?)?.map((e) => e.toString()).toList() ?? [],
  );

  Map<String, dynamic> toJson() => {'message': message, 'items': items};
}
```

**Regras:** extende a Entity; implementa `fromJson()`/`toJson()`; sem lógica de negócio.

---

### DataSource

```dart
class HomeRemoteDataSource {
  const HomeRemoteDataSource(this._httpService);
  final HttpService _httpService;

  Future<HttpResponse> getHomeData() => _httpService.get('/home');
}
```

**Regras:** classe concreta; recebe `HttpService` via construtor; retorna dados brutos; lança exceções (sem try/catch); não retorna Models/Entities.

---

### Repository Implementation (data)

```dart
class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._remoteDataSource);
  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<Result<HomeEntity>> loadHomeData() async {
    try {
      final data = await _remoteDataSource.getHomeData();
      return Result.ok(HomeModel.fromJson(data.body));
    } catch (e) {
      return Result.error(Exception('Failed to load home data: $e'));
    }
  }
}
```

**Regras:** implementa interface do domínio; SEMPRE `try/catch`; retorna `Result<T>`; converte dados em Models.

---

## 🛠️ Configurações

### Result Pattern

```dart
sealed class Result<T> {
  const Result();
  factory Result.ok(T value) => Ok(value);
  factory Result.error(Exception error) => Error(error);
}
final class Ok<T> extends Result<T> { const Ok(this.value); final T value; }
final class Error<T> extends Result<T> { const Error(this.error); final Exception error; }
```

Helpers: `result.when(ok:, error:)` · `result.whenAsync(ok:, error:)` · `result.valueOrNull` · `result.isOk` / `result.isError`

---

### Injeção de Dependências (GetIt)

```dart
// Services, Repositories, DataSources
inject.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(inject()));

// Cubits — nova instância a cada get()
inject.registerFactory<HomeCubit>(() => HomeCubit(inject()));
```

**Regras:** `registerLazySingleton` para tudo exceto Cubits; `registerFactory` para Cubits; nunca registre Widgets ou classes de UI.

---

### Navegação (GoRouter)

```dart
class AppRoutes {
  static const String home = '/home';
}

GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeView())
```

Navegação SEMPRE na View ou `BlocListener` — nunca no Cubit.

---

### Common Services (`common/services/`)

Services abstraem recursos do dispositivo/plataforma (storage, biometria, notificações, IAP). São injetados diretamente no Cubit **sem Repository intermediário**.

| Situação | Solução |
|---|---|
| Persistir preferências/flags/tokens | `StorageService` |
| Recurso do dispositivo | novo `XxxService` em `common/services/` |
| API externa com Entity | `Repository` (domain + data) |

**Regras:** SEMPRE crie interface abstrata + implementação concreta separada; registre como `registerLazySingleton`; injete no Cubit via construtor; nunca acesse da View diretamente.

---

## 📋 Convenções

| Elemento | Convenção | Exemplo |
|---|---|---|
| Arquivos | `snake_case` | `home_view.dart` |
| Classes | `PascalCase` | `HomeCubit` |
| Variáveis/Métodos | `camelCase` | `loadHome()` |
| Privados | `_` prefix | `_cubit` |

- Máximo 80 caracteres por linha
- `const` sempre que possível
- Trailing commas
- `log()` de `dart:developer` — nunca `print()`
- `ListView.builder` para listas longas

### i18n

```dart
// ❌ ERRADO
Text('Bem-vindo')

// ✅ CORRETO
Text(context.l10n.welcomeMessage)
```

Exceções: strings de debug, nomes técnicos de API, dados dinâmicos vindos de API.

---

**Última atualização**: 02 de abril de 2026
