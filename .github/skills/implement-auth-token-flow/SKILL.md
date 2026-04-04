---
name: implement-auth-token-flow
description: Implements the complete Bearer token authentication flow following the project architecture. Covers login → save token, automatic token injection via AuthInterceptor, refresh token before expiration, and redirect to login on 401 (expired token). Generates AuthService, AuthRepository, Login feature (Cubit/State/View), token refresh interceptor, and DI registration. Use whenever the user asks to add authentication, login, token management, user sessions, protected routes, or auto-login to the app. Activate even when the user says 'protect this screen', 'user needs to be logged in', 'handle expired session', 'add JWT auth', 'redirect to login when token expires', 'remember me', or 'keep user logged in' without explicitly mentioning Bearer token or AuthInterceptor.
---

# Implement Auth Token Flow — Flutter

Implementa o fluxo completo de autenticação com Bearer token seguindo a arquitetura do projeto.

## Leitura Rápida

- **Primeiro passo obrigatório**: faça TODAS as perguntas ao usuário (Passo 1) antes de gerar qualquer código.
- **AuthService**: gerencia tokens no `StorageService` — NUNCA faz chamadas HTTP; chaves fixas: `auth_token`, `refresh_token`, `token_expires_at`.
- **TokenRefreshInterceptor**: usa um `Dio` separado (sem interceptors) para o refresh — isso evita loop infinito.
- **Flag `_isRefreshing`**: evita múltiplos refreshes simultâneos — verifique antes de iniciar qualquer refresh.
- **Rotas públicas**: o interceptor ignora `/auth/login`, `/auth/refresh`, etc. — nunca tente refresh nessas rotas.
- **Splash**: sempre verifique `authService.isAuthenticated()` no início e redirecione para Home ou Login.
- **Navegação**: SEMPRE via `appRouter.go()` no interceptor — nunca receba `BuildContext` fora da View.
- **Ordem de DI**: `StorageService` → `AuthService` → `Dio` → `HttpService` → DataSources → Repos → Cubits.
- **Segurança**: NUNCA armazene a senha do usuário; NUNCA logue tokens em produção; use HTTPS.

---

## Visão geral do fluxo

```
┌──────────┐   POST /auth/login   ┌───────────┐
│  Login   │ ───────────────────→ │  API/      │
│  View    │                      │  Back-end  │
└──────────┘                      └───────────┘
     ↓                                  ↓
  LoginCubit                    { access_token, refresh_token, expires_in }
     ↓                                  ↓
  AuthRepository ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘
     ↓
  StorageService.setString('auth_token', accessToken)
  StorageService.setString('refresh_token', refreshToken)
  StorageService.setString('token_expires_at', expiresAt)
     ↓
  Navega para Home
```

**Fluxo de requisições autenticadas:**

```
View → Cubit → Repository → HttpService → Dio
                                            ↓
                                    AuthInterceptor
                                    (injeta Bearer token do StorageService)
                                            ↓
                                    TokenRefreshInterceptor
                                    (se token ≈ expirar → refresh silencioso)
                                            ↓
                                    Se 401 → limpa tokens → redireciona ao Login
```

---

## Passo 1 — Perguntas obrigatórias ao usuário

Antes de gerar qualquer código, faça TODAS as perguntas abaixo em uma única mensagem:

```
1. Qual é o endpoint de login da API?
   Ex: POST /auth/login
   Quais campos são enviados? (ex: email + password, phone + code)

2. Qual é o formato da resposta de login?
   Ex: { "access_token": "...", "refresh_token": "...", "expires_in": 3600 }

3. A API tem endpoint de refresh token?
   - SIM → Qual endpoint? (ex: POST /auth/refresh)
     Qual payload? (ex: { "refresh_token": "..." })
   - NÃO → Token expira e o usuário precisa fazer login novamente

4. Qual margem de tempo para refresh proativo?
   (Sugestão: 5 minutos antes de expirar — 300 segundos)

5. A API tem endpoint de logout?
   - SIM → Qual endpoint? (ex: POST /auth/logout)
   - NÃO → Apenas limpar tokens localmente

6. Existe tela de cadastro (register) junto com login?
   - SIM → Criar na mesma feature
   - NÃO → Apenas login

7. Qual é o nome da feature? (sugestão: "login" ou "auth")
```

Guarde as respostas para guiar toda a implementação.

---

## Passo 2 — Determinar a arquitetura

### Arquitetura do fluxo completo

```
lib/
├── common/
│   └── services/
│       └── auth_service.dart              ← Gerencia tokens no StorageService
│
├── config/
│   └── network/
│       ├── auth_interceptor.dart          ← JÁ EXISTE — injeta Bearer
│       └── token_refresh_interceptor.dart ← NOVO — refresh proativo + 401
│
├── domain/
│   ├── entities/
│   │   └── auth_entity.dart               ← access_token, refresh_token, expiresAt
│   └── interfaces/
│       └── auth_repository.dart           ← login(), refresh(), logout()
│
├── data/
│   ├── models/
│   │   └── auth_model.dart                ← fromJson/toJson, extends AuthEntity
│   ├── datasources/
│   │   └── auth_remote_datasource.dart    ← Chamadas HTTP à API
│   └── repositories/
│       └── auth_repository_impl.dart      ← Implementação com try/catch + Result
│
└── presentation/
    └── login/
        ├── view/
        │   └── login_view.dart
        └── view_model/
            ├── login_cubit.dart
            └── login_state.dart
```

---

## Passo 3 — Implementação passo a passo

### 3.1 — AuthEntity (Domain)

```dart
// lib/domain/entities/auth_entity.dart
import 'package:meta/meta.dart';

@immutable
class AuthEntity {
  const AuthEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// Retorna true se o token já expirou
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Retorna true se o token está prestes a expirar
  /// (dentro da margem de segurança)
  bool isAboutToExpire({
    Duration margin = const Duration(minutes: 5),
  }) {
    return DateTime.now().isAfter(
      expiresAt.subtract(margin),
    );
  }

  AuthEntity copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AuthEntity(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthEntity &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(
        accessToken,
        refreshToken,
        expiresAt,
      );
}
```

### 3.2 — AuthRepository Interface (Domain)

```dart
// lib/domain/interfaces/auth_repository.dart
import 'package:base_app/config/error/result_pattern.dart';
import 'package:base_app/domain/entities/auth_entity.dart';

abstract class AuthRepository {
  /// Realiza login com credenciais e retorna dados de autenticação
  Future<Result<AuthEntity>> login({
    required String email,
    required String password,
  });

  /// Renova o token usando o refresh token
  Future<Result<AuthEntity>> refreshToken({
    required String refreshToken,
  });

  /// Realiza logout no servidor (se aplicável)
  Future<Result<void>> logout({required String refreshToken});
}
```

### 3.3 — AuthModel (Data)

```dart
// lib/data/models/auth_model.dart
import 'package:base_app/domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required super.accessToken,
    required super.refreshToken,
    required super.expiresAt,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'] as int? ?? 3600;
    return AuthModel(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  factory AuthModel.fromEntity(AuthEntity entity) {
    return AuthModel(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      expiresAt: entity.expiresAt,
    );
  }
}
```

### 3.4 — AuthRemoteDataSource (Data)

```dart
// lib/data/datasources/auth_remote_datasource.dart
import 'package:base_app/common/services/http/http_service.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._httpService);
  final HttpService _httpService;

  /// POST /auth/login
  Future<HttpResponse> login({
    required String email,
    required String password,
  }) async {
    return _httpService.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
  }

  /// POST /auth/refresh
  Future<HttpResponse> refreshToken({
    required String refreshToken,
  }) async {
    return _httpService.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
  }

  /// POST /auth/logout
  Future<HttpResponse> logout({
    required String refreshToken,
  }) async {
    return _httpService.post(
      '/auth/logout',
      data: {'refresh_token': refreshToken},
    );
  }
}
```

### 3.5 — AuthRepositoryImpl (Data)

```dart
// lib/data/repositories/auth_repository_impl.dart
import 'package:base_app/config/error/result_pattern.dart';
import 'package:base_app/data/datasources/auth_remote_datasource.dart';
import 'package:base_app/data/models/auth_model.dart';
import 'package:base_app/domain/entities/auth_entity.dart';
import 'package:base_app/domain/interfaces/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);
  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Result<AuthEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      final data = response.data as Map<String, dynamic>;
      return Result.ok(AuthModel.fromJson(data));
    } catch (e) {
      return Result.error(Exception('Failed to login: $e'));
    }
  }

  @override
  Future<Result<AuthEntity>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );
      final data = response.data as Map<String, dynamic>;
      return Result.ok(AuthModel.fromJson(data));
    } catch (e) {
      return Result.error(
        Exception('Failed to refresh token: $e'),
      );
    }
  }

  @override
  Future<Result<void>> logout({
    required String refreshToken,
  }) async {
    try {
      await _remoteDataSource.logout(refreshToken: refreshToken);
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception('Failed to logout: $e'));
    }
  }
}
```

### 3.6 — AuthService (Common)

Serviço responsável por gerenciar tokens no `StorageService`. NÃO faz chamadas HTTP — apenas persiste e recupera dados locais.

```dart
// lib/common/services/auth_service.dart
import 'package:base_app/common/services/storage_service.dart';
import 'package:base_app/domain/entities/auth_entity.dart';

class AuthService {
  const AuthService(this._storage);
  final StorageService _storage;

  static const String _accessTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'token_expires_at';

  /// Salva os dados de autenticação no storage local
  Future<void> saveAuth(AuthEntity auth) async {
    await _storage.setString(_accessTokenKey, auth.accessToken);
    await _storage.setString(_refreshTokenKey, auth.refreshToken);
    await _storage.setString(
      _expiresAtKey,
      auth.expiresAt.toIso8601String(),
    );
  }

  /// Recupera os dados de autenticação salvos
  /// Retorna null se não houver token salvo
  Future<AuthEntity?> getAuth() async {
    final accessToken = await _storage.getString(_accessTokenKey);
    final refreshToken = await _storage.getString(_refreshTokenKey);
    final expiresAtStr = await _storage.getString(_expiresAtKey);

    if (accessToken == null || refreshToken == null) return null;

    final expiresAt = expiresAtStr != null
        ? DateTime.tryParse(expiresAtStr)
        : null;

    if (expiresAt == null) return null;

    return AuthEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  /// Verifica se existe um token salvo e válido (não expirado)
  Future<bool> isAuthenticated() async {
    final auth = await getAuth();
    return auth != null && !auth.isExpired;
  }

  /// Verifica se o token está prestes a expirar
  Future<bool> isTokenAboutToExpire({
    Duration margin = const Duration(minutes: 5),
  }) async {
    final auth = await getAuth();
    if (auth == null) return false;
    return auth.isAboutToExpire(margin: margin);
  }

  /// Remove todos os dados de autenticação
  Future<void> clearAuth() async {
    await _storage.remove(_accessTokenKey);
    await _storage.remove(_refreshTokenKey);
    await _storage.remove(_expiresAtKey);
  }
}
```

### 3.7 — TokenRefreshInterceptor (Config/Network)

Interceptor que faz refresh proativo do token quando está prestes a expirar, e redireciona ao login quando recebe 401.

**IMPORTANTE:** Este interceptor usa `Dio` diretamente (não `HttpService`) para evitar loop infinito — a chamada de refresh NÃO deve passar pelos mesmos interceptors.

```dart
// lib/config/network/token_refresh_interceptor.dart
import 'dart:developer';

import 'package:base_app/common/services/auth_service.dart';
import 'package:base_app/config/routes/app_router.dart';
import 'package:base_app/config/routes/app_routes.dart';
import 'package:base_app/data/models/auth_model.dart';
import 'package:dio/dio.dart';

class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required AuthService authService,
    required String baseUrl,
  })  : _authService = authService,
        _refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

  final AuthService _authService;

  /// Dio separado para refresh — sem interceptors para evitar
  /// loop infinito
  final Dio _refreshDio;

  /// Flag para evitar múltiplos refreshes simultâneos
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Não tenta refresh em rotas públicas (login, register, etc.)
    if (_isPublicRoute(options.path)) {
      return super.onRequest(options, handler);
    }

    final auth = await _authService.getAuth();
    if (auth == null) {
      return super.onRequest(options, handler);
    }

    // Se o token está prestes a expirar, tenta refresh proativo
    if (auth.isAboutToExpire() && !_isRefreshing) {
      await _tryRefreshToken(auth.refreshToken);
    }

    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final auth = await _authService.getAuth();

      // Tenta refresh uma vez antes de deslogar
      if (auth != null && !_isRefreshing) {
        final refreshed = await _tryRefreshToken(
          auth.refreshToken,
        );

        if (refreshed) {
          // Retry da requisição original com o novo token
          try {
            final newAuth = await _authService.getAuth();
            if (newAuth != null) {
              err.requestOptions.headers['Authorization'] =
                  'Bearer ${newAuth.accessToken}';

              final response = await _refreshDio.fetch(
                err.requestOptions,
              );
              return handler.resolve(response);
            }
          } catch (retryError) {
            log(
              'Retry failed after refresh: $retryError',
              name: 'TokenRefreshInterceptor',
            );
          }
        }

        // Refresh falhou → limpar tokens e redirecionar ao login
        await _handleSessionExpired();
        return handler.next(err);
      }

      // Sem token ou já estava tentando refresh → sessão expirada
      await _handleSessionExpired();
    }

    super.onError(err, handler);
  }

  /// Tenta renovar o token. Retorna true se obteve sucesso.
  Future<bool> _tryRefreshToken(String refreshToken) async {
    _isRefreshing = true;
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh', // ← ajuste conforme endpoint real
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAuth = AuthModel.fromJson(response.data!);
        await _authService.saveAuth(newAuth);
        log('Token refreshed successfully',
            name: 'TokenRefreshInterceptor');
        return true;
      }

      return false;
    } catch (e) {
      log(
        'Token refresh failed: $e',
        name: 'TokenRefreshInterceptor',
      );
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Limpa tokens e redireciona para a tela de login
  Future<void> _handleSessionExpired() async {
    await _authService.clearAuth();
    log(
      'Session expired — redirecting to login',
      name: 'TokenRefreshInterceptor',
    );
    appRouter.go(AppRoutes.login);
  }

  /// Define quais rotas NÃO precisam de token
  /// (evita tentar refresh em chamadas de login/register)
  bool _isPublicRoute(String path) {
    const publicPaths = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
      '/auth/forgot-password',
    ];
    return publicPaths.any(path.contains);
  }
}
```

### 3.8 — Atualizar `dio_client.dart`

Adicionar o `TokenRefreshInterceptor` ao Dio:

```dart
// lib/config/network/dio_client.dart
import 'package:base_app/common/services/auth_service.dart';
import 'package:base_app/common/services/storage_service.dart';
import 'package:base_app/config/network/auth_interceptor.dart';
import 'package:base_app/config/network/error_interceptor.dart';
import 'package:base_app/config/network/token_refresh_interceptor.dart';
import 'package:dio/dio.dart';

Dio makeDio({
  required StorageService storageService,
  required AuthService authService,
  String baseUrl = 'https://api.example.com',
  bool enableLogs = false,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  if (enableLogs) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  // Ordem dos interceptors importa:
  // 1. TokenRefresh — renova token se necessário (antes de injetar)
  // 2. Auth — injeta Bearer token no header
  // 3. Error — mapeia erros HTTP
  dio.interceptors.add(
    TokenRefreshInterceptor(
      authService: authService,
      baseUrl: baseUrl,
    ),
  );
  dio.interceptors.add(AuthInterceptor(storageService));
  dio.interceptors.add(ErrorInterceptor());

  return dio;
}
```

### 3.9 — LoginState (Presentation)

```dart
// lib/presentation/login/view_model/login_state.dart
import 'package:meta/meta.dart';

@immutable
sealed class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess();
}

class LoginError extends LoginState {
  const LoginError(this.message);
  final String message;
}
```

### 3.10 — LoginCubit (Presentation)

```dart
// lib/presentation/login/view_model/login_cubit.dart
import 'package:base_app/common/services/auth_service.dart';
import 'package:base_app/domain/interfaces/auth_repository.dart';
import 'package:base_app/presentation/login/view_model/login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._authRepository, this._authService)
      : super(const LoginInitial());

  final AuthRepository _authRepository;
  final AuthService _authService;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const LoginLoading());

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    result.when(
      ok: (auth) async {
        await _authService.saveAuth(auth);
        emit(const LoginSuccess());
      },
      error: (e) => emit(LoginError('$e')),
    );
  }

  Future<void> logout() async {
    emit(const LoginLoading());

    final auth = await _authService.getAuth();
    if (auth != null) {
      await _authRepository.logout(
        refreshToken: auth.refreshToken,
      );
    }

    await _authService.clearAuth();
    emit(const LoginInitial());
  }
}
```

### 3.11 — LoginView (Presentation)

```dart
// lib/presentation/login/view/login_view.dart
import 'package:base_app/config/inject/app_injector.dart';
import 'package:base_app/config/routes/app_routes.dart';
import 'package:base_app/l10n/l10n.dart';
import 'package:base_app/presentation/login/view_model/login_cubit.dart';
import 'package:base_app/presentation/login/view_model/login_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _cubit = AppInjector.inject.get<LoginCubit>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cubit.close();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<LoginCubit, LoginState>(
          bloc: _cubit,
          listener: (context, state) {
            if (state is LoginSuccess) {
              context.go(AppRoutes.home);
            }
            if (state is LoginError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is LoginLoading;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: l10n.loginEmailLabel,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.loginPasswordLabel,
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _onLoginPressed,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.loginButtonLabel),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      _cubit.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }
}
```

### 3.12 — DI (app_injector.dart)

Adicionar ao `setupDependencies`:

```dart
// AuthService (usa StorageService já registrado)
..registerLazySingleton<AuthService>(
  () => AuthService(inject()),
)
// Dio agora recebe AuthService
..registerLazySingleton<Dio>(
  () => makeDio(
    storageService: inject(),
    authService: inject(),
    baseUrl: baseUrl,
    enableLogs: enableLogs,
  ),
)
// Auth DataSource
..registerLazySingleton<AuthRemoteDataSource>(
  () => AuthRemoteDataSource(inject()),
)
// Auth Repository
..registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(inject()),
)
// Login Cubit
..registerFactory<LoginCubit>(
  () => LoginCubit(inject(), inject()),
)
```

**Ordem de registro importa:** `StorageService` → `AuthService` → `Dio` → `HttpService` → DataSources → Repositories → Cubits.

### 3.13 — Rotas

```dart
// app_routes.dart — adicionar:
static const String login = '/login';

// app_router.dart — adicionar GoRoute:
GoRoute(
  path: AppRoutes.login,
  builder: (context, state) => const LoginView(),
),
```

### 3.14 — SplashView: verificar autenticação

A Splash deve verificar se já existe token válido:

```dart
// No SplashCubit ou na SplashView:
final authService = AppInjector.inject.get<AuthService>();
final isAuthenticated = await authService.isAuthenticated();

if (isAuthenticated) {
  context.go(AppRoutes.home);
} else {
  context.go(AppRoutes.login);
}
```

### 3.15 — Strings i18n

Adicionar nos arquivos ARB:

```json
// app_pt.arb
{
  "loginEmailLabel": "E-mail",
  "loginPasswordLabel": "Senha",
  "loginButtonLabel": "Entrar",
  "loginErrorGeneric": "Erro ao fazer login. Tente novamente.",
  "logoutButtonLabel": "Sair"
}

// app_en.arb
{
  "loginEmailLabel": "Email",
  "loginPasswordLabel": "Password",
  "loginButtonLabel": "Sign in",
  "loginErrorGeneric": "Failed to sign in. Please try again.",
  "logoutButtonLabel": "Sign out"
}
```

---

## Passo 4 — Fluxo de decisão: com ou sem refresh token

```
A API fornece refresh_token na resposta de login?
  ├─ SIM → Criar TokenRefreshInterceptor completo:
  │         ✅ Refresh proativo (antes de expirar)
  │         ✅ Refresh reativo (ao receber 401)
  │         ✅ Retry da requisição original após refresh
  │         ✅ Redireciona ao login se refresh falhar
  │
  └─ NÃO → Criar interceptor simplificado:
            ✅ Ao receber 401 → limpa tokens → redireciona ao login
            ❌ Sem refresh proativo
            ❌ Sem retry de requisição
```

**Interceptor simplificado (sem refresh):**

```dart
class TokenExpirationInterceptor extends Interceptor {
  TokenExpirationInterceptor(this._authService);
  final AuthService _authService;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _authService.clearAuth();
      appRouter.go(AppRoutes.login);
    }
    super.onError(err, handler);
  }
}
```

---

## Passo 5 — Checklist de implementação

### AuthEntity
- [ ] `@immutable`, `const`, `final`
- [ ] `copyWith()`, `==`, `hashCode`
- [ ] `isExpired` e `isAboutToExpire()` implementados
- [ ] Sem dependências externas (clean domain)

### AuthModel
- [ ] Extends `AuthEntity`
- [ ] `fromJson()` com defaults seguros (ex: `?? ''`)
- [ ] `toJson()` implementado
- [ ] `expires_in` convertido para `DateTime` (não armazenar como int)

### AuthRepository Interface
- [ ] Retorna `Result<T>` em todos os métodos
- [ ] Métodos: `login()`, `refreshToken()`, `logout()`
- [ ] Sem dependências de `data/`

### AuthRepositoryImpl
- [ ] `try/catch` em TODOS os métodos
- [ ] Retorna `Result.error(Exception(...))` no catch
- [ ] Converte response para `AuthModel.fromJson()`

### AuthService
- [ ] Usa `StorageService` (nunca `SharedPreferences` direto)
- [ ] Chaves constantes: `auth_token`, `refresh_token`, `token_expires_at`
- [ ] `saveAuth()`, `getAuth()`, `clearAuth()`, `isAuthenticated()`
- [ ] `isTokenAboutToExpire()` com margem configurável

### TokenRefreshInterceptor
- [ ] Usa `Dio` separado para refresh (sem interceptors — evita loop)
- [ ] Flag `_isRefreshing` para evitar refresh simultâneo
- [ ] Ignora rotas públicas (`_isPublicRoute`)
- [ ] Retry da requisição original após refresh
- [ ] `_handleSessionExpired()` limpa tokens e navega para login
- [ ] Usa `appRouter.go()` para navegação (não `context`)

### AuthInterceptor (já existe)
- [ ] Lê token do `StorageService` a cada request
- [ ] Não precisa de alteração se o `AuthService` já salva na mesma chave

### LoginCubit
- [ ] Recebe `AuthRepository` e `AuthService` via construtor
- [ ] Emite `LoginLoading` antes de chamar repository
- [ ] Usa `result.when()` para tratar Result
- [ ] `saveAuth()` chamado no `ok:` do result
- [ ] `logout()` limpa tokens via `AuthService.clearAuth()`

### LoginView
- [ ] `SafeArea` envolvendo conteúdo
- [ ] `BlocConsumer` (listener para navegação, builder para UI)
- [ ] Navegação no `listener` (nunca no Cubit)
- [ ] Textos via `context.l10n.<chave>`
- [ ] `_cubit.close()` no `dispose()`
- [ ] Form com `TextFormField` para email/password
- [ ] Desabilita campos durante loading

### DI
- [ ] `AuthService` → `registerLazySingleton`
- [ ] `AuthRemoteDataSource` → `registerLazySingleton`
- [ ] `AuthRepository` → `registerLazySingleton`
- [ ] `LoginCubit` → `registerFactory`
- [ ] Ordem: StorageService → AuthService → Dio → HttpService → ...

### Rotas
- [ ] `AppRoutes.login` definida
- [ ] GoRoute adicionada no `appRouter`
- [ ] Splash verifica `isAuthenticated()` e redireciona

### i18n
- [ ] Strings de login nos arquivos `app_en.arb` e `app_pt.arb`
- [ ] Zero strings hardcoded na View

---

## Passo 6 — Segurança

### Obrigatório

- **NUNCA** armazene a senha do usuário localmente
- **NUNCA** log o token em produção (apenas development)
- **NUNCA** envie o refresh_token no header — use apenas no body da chamada de refresh
- **NUNCA** confie apenas no client para validar expiração — o servidor é a fonte de verdade
- **SEMPRE** use HTTPS (nunca HTTP) para endpoints de autenticação
- **SEMPRE** limpe os tokens ao receber 401 após falha no refresh
- **SEMPRE** use `Dio` separado para refresh (sem AuthInterceptor) para evitar loop infinito

### Recomendado

- Considere usar `flutter_secure_storage` em vez de `SharedPreferences` para tokens sensíveis (armazenamento criptografado no Keychain/Keystore)
- Implemente rate limiting no login para evitar brute force
- Adicione biometria como segundo fator se o app exigir alta segurança

---

## Anti-patterns a evitar

- ❌ NÃO receba `BuildContext` no Cubit — navegação SEMPRE na View/BlocListener
- ❌ NÃO salve tokens diretamente com `SharedPreferences` — use `StorageService`
- ❌ NÃO faça refresh usando o mesmo `Dio` com interceptors — cria loop infinito
- ❌ NÃO ignore o `dispose()` do Cubit na View
- ❌ NÃO crie `Widget _buildXxx()` na View — extraia para `widgets/` ou `content/`
- ❌ NÃO hardcode strings na UI — use `context.l10n`
- ❌ NÃO armazene `expires_in` como int — converta para `DateTime` no Model
- ❌ NÃO faça múltiplos refreshes simultâneos — use flag `_isRefreshing`
- ❌ NÃO tente refresh em rotas públicas (login, register)
- ❌ NÃO desbloqueie funcionalidades protegidas sem validar o token primeiro

---

**Última atualização**: 28 de março de 2026
