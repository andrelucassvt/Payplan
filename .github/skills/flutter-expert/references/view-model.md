# View Model (Cubit e State) — Flutter

## Leitura Rápida

- **Quando criar um State**: SEMPRE `sealed class` + `@immutable` + `const`; mínimo obrigatório: `Initial`, `Loading`, `Loaded`, `Error`; garanta também `toString()` legível no `BlocObserver`.
- **Quando criar um Cubit**: receba dependências via construtor; NUNCA injete DataSource diretamente — use Repository.
- **Quando escrever um método async no Cubit**: SEMPRE emita `Loading` primeiro → chame o repository → use `result.when()`.
- **Quando emitir erro**: emita a **causa** (enum `XErrorKind`), nunca o texto — o Cubit não tem `context.l10n`. Guarde a `AppException` original no campo `error` para o log.
- **Quando o Cubit precisar navegar**: emita um estado de navegação (`XNavigateToY`) e deixe a View reagir via `BlocListener`.
- **Quando persistir dados localmente** (preferências, cache, flags): injete `StorageService` diretamente no Cubit — sem Repository, sem DataSource.

---

## Estrutura

```
lib/presentation/<feature>/view_model/
├── <feature>_state.dart        # Estados da feature
└── <feature>_cubit.dart        # Gerenciador de estado
```

---

## Criando States

### Template Base

```dart
import 'package:flutter/foundation.dart';

@immutable
sealed class ProfileState {
  const ProfileState();

  @override
  String toString();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();

  @override
  String toString() => 'ProfileInitial';
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();

  @override
  String toString() => 'ProfileLoading';
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  @override
  String toString() => 'ProfileLoaded(name: $name, email: $email)';
}

class ProfileError extends ProfileState {
  const ProfileError(this.kind, {this.error, this.stackTrace});

  /// Causa em forma de dado — a View traduz com context.l10n.
  final ProfileErrorKind kind;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'ProfileError(kind: $kind, error: $error, stackTrace: $stackTrace)';
}

enum ProfileErrorKind { offline, sessionExpired, notFound, generic }
```

### O State de erro carrega a causa, não o texto

O Cubit não tem `BuildContext`, logo não tem acesso a `context.l10n`. Uma mensagem literal no Cubit
(`emit(ProfileError('Erro ao carregar perfil'))`) quebra a regra de zero strings hardcoded e trava
o app em um idioma só. Emita a **causa**; a View resolve o texto:

```dart
// Cubit — classifica pelo tipo da falha vinda do Repository
result.when(
  ok: (data) => emit(ProfileLoaded(name: data.name, email: data.email)),
  error: (e) => emit(
    ProfileError(
      switch (e) {
        NetworkException() => ProfileErrorKind.offline,
        UnauthorizedException() => ProfileErrorKind.sessionExpired,
        NotFoundException() => ProfileErrorKind.notFound,
        _ => ProfileErrorKind.generic,
      },
      error: e,
    ),
  ),
);

// View — único lugar com acesso ao l10n
if (state is ProfileError) {
  return Center(
    child: Text(switch (state.kind) {
      ProfileErrorKind.offline => l10n.errorOffline,
      ProfileErrorKind.sessionExpired => l10n.errorSessionExpired,
      ProfileErrorKind.notFound => l10n.errorProfileNotFound,
      ProfileErrorKind.generic => l10n.errorGeneric,
    }),
  );
}
```

> `enum` aqui é uma exceção deliberada à preferência por `if` + early return no `builder`: a regra
> do `if` vale para **discriminar o State**; para mapear um enum, `switch` exaustivo é o idioma
> correto e o compilador cobra o caso novo.
>
> O campo `error` continua guardando a `AppException` original — ele nunca vai para a tela, só para
> o log do `BlocObserver`.

### Regras Obrigatórias para States

1. **SEMPRE sealed class** — pattern matching exaustivo
2. **SEMPRE @immutable**
3. **SEMPRE const** no construtor
4. **Propriedades SEMPRE final**
5. **Estados mínimos**: Initial, Loading, Loaded, Error
6. **SEMPRE `toString()` legível** — declare-o abstrato na classe base; cada State concreto retorna um nome explícito e mostra os campos relevantes quando houver payload
7. **NUNCA adicione métodos de negócio** — States carregam dados; `toString()` é a exceção diagnóstica

### Logs legíveis no BlocObserver

O `Change` do BLoC usa o `toString()` dos States. Sem sobrescrita, o log perde o payload:

```text
Change { currentState: Instance of 'HomeLoading', nextState: Instance of 'HomeLoaded' }
```

Declare `toString()` como abstrato na `sealed class`. Assim, todo novo State precisa implementar o log. Use nomes explícitos — além de estáveis, eles evitam o lint `no_runtimetype_tostring`:

```dart
@immutable
sealed class HomeState {
  const HomeState();

  @override
  String toString();
}

class HomeLoading extends HomeState {
  const HomeLoading();

  @override
  String toString() => 'HomeLoading';
}

class HomeLoaded extends HomeState {
  const HomeLoaded({required this.items});

  final List<HomeItemEntity> items;

  @override
  String toString() => 'HomeLoaded(items: $items)';
}

class HomeError extends HomeState {
  const HomeError(this.kind, {this.error, this.stackTrace});

  final HomeErrorKind kind;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'HomeError(kind: $kind, error: $error, stackTrace: $stackTrace)';
}

enum HomeErrorKind { offline, generic }
```

O resultado passa a ser útil para diagnóstico:

```text
Change { currentState: HomeLoading, nextState: HomeLoaded(items: [...]) }
Change { currentState: HomeLoading, nextState: HomeError(kind: HomeErrorKind.offline, error: SocketException: ..., stackTrace: ...) }
```

Regras de observabilidade:

- Mostre o nome do State e os nomes dos campos; `HomeLoaded(items: ...)` é mais claro que apenas os valores.
- Em erros, mantenha a mensagem amigável separada do erro técnico. Passe `error` recebido do Repository e capture `stackTrace` em `catch (error, stackTrace)` quando ele estiver disponível.
- Nunca inclua senha, token, cookie, documento ou outro dado sensível no `toString()`.
- Para listas/objetos muito grandes, registre contagem, identificadores ou uma amostra curta em vez de serializar todo o payload.
- Se um payload aparecer como `Instance of 'X'`, implemente também um `toString()` seguro nessa Entity/Value Object ou resuma seus campos no próprio State.

---

## Tipos de State por Feature

### Feature CRUD

```dart
@immutable
sealed class ProductsState {
  const ProductsState();

  @override
  String toString();
}

class ProductsInitial extends ProductsState {
  const ProductsInitial();

  @override
  String toString() => 'ProductsInitial';
}
class ProductsLoading extends ProductsState {
  const ProductsLoading();

  @override
  String toString() => 'ProductsLoading';
}
class ProductsLoaded extends ProductsState {
  const ProductsLoaded({required this.products});
  final List<ProductEntity> products;

  @override
  String toString() => 'ProductsLoaded(products: $products)';
}
class ProductsCreating extends ProductsState {
  const ProductsCreating();

  @override
  String toString() => 'ProductsCreating';
}
class ProductsUpdating extends ProductsState {
  const ProductsUpdating();

  @override
  String toString() => 'ProductsUpdating';
}
class ProductsDeleting extends ProductsState {
  const ProductsDeleting();

  @override
  String toString() => 'ProductsDeleting';
}
class ProductsError extends ProductsState {
  const ProductsError(this.kind, {this.error});
  final ProductsErrorKind kind;
  final Object? error;

  @override
  String toString() => 'ProductsError(kind: $kind, error: $error)';
}

/// A operação que falhou faz parte da causa — a View escolhe o texto.
enum ProductsErrorKind { load, create, update, delete, offline }
```

### Feature com Formulário

```dart
@immutable
sealed class RegisterState {
  const RegisterState();

  @override
  String toString();
}

class RegisterInitial extends RegisterState {
  const RegisterInitial();

  @override
  String toString() => 'RegisterInitial';
}
class RegisterValidating extends RegisterState {
  const RegisterValidating();

  @override
  String toString() => 'RegisterValidating';
}
class RegisterSubmitting extends RegisterState {
  const RegisterSubmitting();

  @override
  String toString() => 'RegisterSubmitting';
}
class RegisterSuccess extends RegisterState {
  const RegisterSuccess({required this.userId});
  final String userId;

  @override
  String toString() => 'RegisterSuccess(userId: $userId)';
}
class RegisterError extends RegisterState {
  const RegisterError(this.kind, {this.error});
  final RegisterErrorKind kind;
  final Object? error;

  @override
  String toString() => 'RegisterError(kind: $kind, error: $error)';
}
class RegisterFieldError extends RegisterState {
  const RegisterFieldError({this.emailError, this.passwordError});
  final FieldErrorKind? emailError;
  final FieldErrorKind? passwordError;

  @override
  String toString() =>
      'RegisterFieldError(emailError: $emailError, passwordError: $passwordError)';
}

enum RegisterErrorKind { emailAlreadyUsed, weakPassword, offline, generic }

/// Erros de campo também são causa, não texto — o `errorText` do
/// TextFormField é resolvido na View com context.l10n.
enum FieldErrorKind { required, invalidFormat, tooShort }
```

### Feature com Paginação

```dart
@immutable
sealed class PostsState {
  const PostsState();

  @override
  String toString();
}

class PostsInitial extends PostsState {
  const PostsInitial();

  @override
  String toString() => 'PostsInitial';
}
class PostsLoading extends PostsState {
  const PostsLoading();

  @override
  String toString() => 'PostsLoading';
}
class PostsLoaded extends PostsState {
  const PostsLoaded({required this.posts, required this.hasMore});
  final List<PostEntity> posts;
  final bool hasMore;

  @override
  String toString() =>
      'PostsLoaded(posts: $posts, hasMore: $hasMore)';
}
class PostsLoadingMore extends PostsState {
  const PostsLoadingMore({required this.currentPosts});
  final List<PostEntity> currentPosts;

  @override
  String toString() =>
      'PostsLoadingMore(currentPosts: $currentPosts)';
}
class PostsError extends PostsState {
  const PostsError(this.kind, {this.error});
  final PostsErrorKind kind;
  final Object? error;

  @override
  String toString() => 'PostsError(kind: $kind, error: $error)';
}

enum PostsErrorKind { firstPage, nextPage, offline }
```

---

## Criando Cubits

### Opção A: Cubit apenas UI / mock (sem fonte de dados)

Use quando a tela tem apenas estado de UI local (ex: tabs, toggles, contadores simples) ou para desenvolvimento com dados mockados. Não há `Result<T>` aqui porque não há chamada assíncrona real.

```dart
import 'package:base_app/presentation/<feature>/view_model/<feature>_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(const CounterInitial());

  void increment(int current) => emit(CounterLoaded(count: current + 1));
  void decrement(int current) => emit(CounterLoaded(count: current - 1));
}
```

### Opção A2: Cubit com StorageService (dados locais)

Use quando precisar persistir dados localmente (preferências, cache, flags de onboarding) **sem** API externa. Injete `StorageService` diretamente — sem Repository.

```dart
import 'package:base_app/common/services/storage_service.dart';
import 'package:base_app/presentation/settings/view_model/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._storage) : super(const SettingsInitial());

  final StorageService _storage;

  Future<void> loadSettings() async {
    emit(const SettingsLoading());
    try {
      final theme = await _storage.getString('theme') ?? 'light';
      emit(SettingsLoaded(theme: theme));
    } catch (error, stackTrace) {
      emit(
        SettingsError(
          SettingsErrorKind.generic,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> saveTheme(String theme) async {
    await _storage.setString('theme', theme);
    emit(SettingsLoaded(theme: theme));
  }
}
```

O State correspondente deve expor `SettingsErrorKind`, não uma mensagem literal. A View traduz a causa
com `context.l10n`, mantendo o Cubit independente de idioma.

**Registro no DI:**
```dart
inject.registerFactory<SettingsCubit>(() => SettingsCubit(inject()));
```

### Opção B: Cubit com Repository (API / banco de dados externo)

```dart
import 'package:base_app/domain/interfaces/<feature>_repository.dart';
import 'package:base_app/presentation/<feature>/view_model/<feature>_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileInitial());

  final ProfileRepository _repository;

  Future<void> loadProfile() async {
    emit(const ProfileLoading());

    final result = await _repository.getData();

    result.when(
      ok: (data) => emit(ProfileLoaded(name: data.name, email: data.email)),
      error: (e) => emit(ProfileError(_kindOf(e), error: e)),
    );
  }

  ProfileErrorKind _kindOf(Object error) => switch (error) {
        NetworkException() => ProfileErrorKind.offline,
        UnauthorizedException() => ProfileErrorKind.sessionExpired,
        NotFoundException() => ProfileErrorKind.notFound,
        _ => ProfileErrorKind.generic,
      };
}
```

### Opção C: Cubit CRUD Completo

```dart
class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._repository) : super(const ProductsInitial());

  final ProductsRepository _repository;

  Future<void> loadAll() async {
    emit(const ProductsLoading());
    final result = await _repository.getAll();
    result.when(
      ok: (data) => emit(ProductsLoaded(products: data)),
      error: (e) => emit(ProductsError(_kindOf(e, ProductsErrorKind.load), error: e)),
    );
  }

  Future<void> create(ProductEntity entity) async {
    emit(const ProductsCreating());
    final result = await _repository.create(entity);
    result.when(
      ok: (_) => loadAll(),
      error: (e) => emit(ProductsError(_kindOf(e, ProductsErrorKind.create), error: e)),
    );
  }

  Future<void> update(ProductEntity entity) async {
    emit(const ProductsUpdating());
    final result = await _repository.update(entity);
    result.when(
      ok: (_) => loadAll(),
      error: (e) => emit(ProductsError(_kindOf(e, ProductsErrorKind.update), error: e)),
    );
  }

  Future<void> delete(String id) async {
    emit(const ProductsDeleting());
    final result = await _repository.delete(id);
    result.when(
      ok: (_) => loadAll(),
      error: (e) => emit(ProductsError(_kindOf(e, ProductsErrorKind.delete), error: e)),
    );
  }

  /// Sem rede vence a operação: a mensagem útil é "você está offline",
  /// não "falha ao atualizar".
  ProductsErrorKind _kindOf(Object error, ProductsErrorKind operation) =>
      error is NetworkException ? ProductsErrorKind.offline : operation;
}
```

---

## Regras Obrigatórias para Cubits

1. **Sempre herda de Cubit** — `class XCubit extends Cubit<XState>`
2. **Estado inicial no construtor** — `: super(const XInitial())`
3. **Sempre emite Loading antes de operações assíncronas**
4. **Usa `result.when()`** para tratar `Result<T>` vindo de um Repository
5. **Converte erros técnicos em mensagens amigáveis**
6. **NUNCA acessa DataSources diretamente** — use Repository
7. **NUNCA contém lógica de UI** (cores, tamanhos, etc.)
8. **Dados locais**: injete `StorageService` diretamente — sem Repository

### Tabela de decisão: qual dependência injetar?

| Cenário | Dependência no Cubit |
|---|---|
| Apenas estado de UI local / mock | Nenhuma |
| Persistência local (prefs, cache, flags) | `StorageService` |
| API REST / banco de dados externo | `XRepository` (interface do domínio) |

### ✅ result.when() vs switch — qual usar?

```dart
// ✅ result.when() — preferido, mais conciso
result.when(
  ok: (data) => emit(LoginSuccess(user: data)),
  error: (e) => emit(LoginError(LoginErrorKind.invalidCredentials, error: e)),
);

// ✅ switch com destructuring — para lógica complexa
switch (result) {
  case Ok<User>(:final value):
    emit(LoginSuccess(user: value));
  case Error<User>(:final error):
    emit(LoginError(LoginErrorKind.invalidCredentials, error: error));
}

// ❌ if/else — nunca use
if (result is Ok) { emit(LoginSuccess()); }
```

---

## Padrões Comuns

### Atualizar Campo Individual

```dart
void updateEmail(String email) {
  final currentState = state;
  if (currentState is LoginLoaded) {
    emit(LoginLoaded(email: email, password: currentState.password));
  }
}
```

### Debounce (Busca com Delay)

```dart
import 'dart:async';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._repository) : super(const SearchInitial());

  final SearchRepository _repository;
  Timer? _debounce;

  void search(String query) {
    _debounce?.cancel();
    if (query.isEmpty) { emit(const SearchInitial()); return; }
    emit(const SearchLoading());
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await _repository.search(query);
      result.when(
        ok: (data) => emit(SearchLoaded(results: data)),
        error: (e) => emit(SearchError(SearchErrorKind.generic, error: e)),
      );
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
```

### Estado de Navegação

Válido quando a View de origem é **descartada** na transição (`go`/`replace`), como login → home.
Se a View sobrevive (`push`), o estado de navegação substitui o de conteúdo e a tela fica em branco —
nesse caso navegue direto na View. Ver `navigation.md`.

```dart
class LoginNavigateToHome extends LoginState {
  const LoginNavigateToHome();

  @override
  String toString() => 'LoginNavigateToHome';
}

// No Cubit
result.when(
  ok: (_) => emit(const LoginNavigateToHome()),
  error: (e) => emit(LoginError(LoginErrorKind.invalidCredentials, error: e)),
);

// Na View
BlocListener<LoginCubit, LoginState>(
  listener: (context, state) {
    if (state is LoginNavigateToHome) context.go(AppRoutes.home);
  },
  child: /* ... */,
)
```

---

## Checklist

### State:
- [ ] Arquivo em `lib/presentation/<feature>/view_model/<feature>_state.dart`
- [ ] `@immutable` + `sealed class`
- [ ] Estados mínimos: Initial, Loading, Loaded, Error
- [ ] Propriedades `final`, construtores `const`
- [ ] Classe base declara `toString()` abstrato; cada State concreto retorna nome explícito e mostra campos relevantes
- [ ] State de erro mostra mensagem e erro técnico/stack trace quando disponíveis, sem expor dados sensíveis

### Cubit:
- [ ] Arquivo em `lib/presentation/<feature>/view_model/<feature>_cubit.dart`
- [ ] Extende `Cubit<XState>`, estado inicial no construtor
- [ ] Dependência correta: `StorageService` (local) ou `XRepository` (API) — nunca DataSource
- [ ] Emite Loading antes de async
- [ ] Usa `result.when()` para tratar `Result<T>` de Repository; `try/catch` para `StorageService`

### Registro no DI:
```dart
// Com Repository:
inject.registerFactory<LoginCubit>(() => LoginCubit(inject()));
// Com StorageService:
inject.registerFactory<SettingsCubit>(() => SettingsCubit(inject()));
```

---

## Erros Comuns

| Erro | Correto |
|---|---|
| `abstract class LoginState` | `sealed class LoginState` |
| Sem `@immutable` | `@immutable sealed class LoginState` |
| Sem `emit(Loading)` antes de async | `emit(const XLoading()); final result = await...` |
| `if (result is Ok)` | `result.when(ok: ..., error: ...)` |
| Cubit recebe DataSource | Cubit recebe Repository |
| Propriedade `String name` sem `final` | `final String name` |
| Log mostra `Instance of 'HomeLoaded'` | Classe base declara `toString()` abstrato e `HomeLoaded.toString()` retorna nome explícito com os campos relevantes |
| State de erro oculta a causa | Inclua `error`/`stackTrace` no State e no `toString()` seguro |
| `emit(XError('Erro ao carregar'))` com texto literal | `emit(XError(XErrorKind.generic, error: e))` — a View traduz com `context.l10n` |
