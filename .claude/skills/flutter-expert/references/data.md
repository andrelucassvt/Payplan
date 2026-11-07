# Data Layer — Flutter

## Leitura Rápida

- **Quando criar um Model**: SEMPRE estenda a Entity correspondente, implemente `fromJson()` (defaults só em campos opcionais), `toJson()`, e `copyWith()` retornando o Model.
- **Quando criar um DataSource**: retorne dados brutos (`HttpResponse`/`Map`/`List`) e NUNCA trate erros — deixe o Repository tratá-los.
- **Quando criar um RepositoryImpl**: `try/catch (error, stackTrace)`, `ensureSuccess(response)` antes do parsing, classifique em `AppException` e retorne `Result<T>` — nunca `throw`.
- **Quando injetar dependências no DataSource**: receba `HttpService` (não Dio diretamente) via construtor.
- **Quando houver lógica de negócio**: NÃO coloque no Data — Data apenas transforma e transporta.

---

## Estrutura

```
lib/data/
├── models/
│   ├── user_model.dart
│   └── product_model.dart
├── datasources/
│   ├── user_remote_datasource.dart
│   └── user_local_datasource.dart
└── repositories/
    ├── user_repository_impl.dart
    └── product_repository_impl.dart
```

---

## Criando Models (DTOs)

### Template Base

```dart
import 'package:base_app/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': final String id,
        'name': final String name,
        'email': final String email,
      } => UserModel(id: id, name: name, email: email),
      _ => throw const ResponseParsingException(
          'UserModel: campos obrigatórios ausentes ou inválidos',
        ),
    };
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }

  @override
  UserModel copyWith({String? id, String? name, String? email}) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(id: entity.id, name: entity.name, email: entity.email);
  }
}
```

### Model com Lista

```dart
class HomeModel extends HomeEntity {
  const HomeModel({required super.message, required super.items});

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    return HomeModel(
      message: json['message'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],  // ✅ Lista vazia como default
    );
  }

  Map<String, dynamic> toJson() => {'message': message, 'items': items};

  @override
  HomeModel copyWith({String? message, List<String>? items}) {
    return HomeModel(message: message ?? this.message, items: items ?? this.items);
  }
}
```

### Model com Objetos Aninhados

```dart
class UserModel extends UserEntity {
  const UserModel({required super.id, required super.name, required super.address});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'] as Map<String, dynamic>)
          : const AddressModel(street: '', city: '', zipCode: ''),
    );
  }
}
```

### Regras para Models

1. **Sempre estende a Entity** — `class UserModel extends UserEntity`
2. **Defaults apenas em campos opcionais** — ver a ressalva abaixo
3. **`toJson()` implementado**
4. **`copyWith()` override retornando Model** (não Entity)
5. **`fromEntity()` quando necessário**

### ⚠️ Defaults não podem mascarar resposta inválida

`json['id'] as String? ?? ''` protege contra campo ausente — e também transforma um corpo de erro
em objeto vazio. Um `500` cujo body é `{"error": "..."}` vira `UserModel(id: '', name: '', email: '')`
e o Repository devolve `Result.ok`. A tela mostra conteúdo em branco em vez do erro.

Separe os dois casos:

```dart
factory UserModel.fromJson(Map<String, dynamic> json) {
  return switch (json) {
    {
      'id': final String id,
      'name': final String name,
      'email': final String email,
    } => UserModel(
        id: id,
        name: name,
        email: email,
        nickname: json['nickname'] as String?, // opcional, fora do contrato mínimo
      ),
    _ => throw const ResponseParsingException(
        'UserModel: campos obrigatórios ausentes ou inválidos',
      ),
  };
}
```

Regra prática: **identidade e campos sem os quais a tela não funciona → lance**; campos de exibição
que podem faltar legitimamente → default. Nunca use default para disfarçar que a resposta veio errada.

---

## Criando DataSources

### Remote DataSource (API)

```dart
import 'package:base_app/common/services/http/http_service.dart';

class UserRemoteDataSource {
  const UserRemoteDataSource(this._httpService);

  final HttpService _httpService;

  Future<HttpResponse> getUsers() async {
    return _httpService.get('/users');
  }

  Future<HttpResponse> getUserById(String id) async {
    return _httpService.get('/users/$id');
  }

  Future<HttpResponse> createUser(Map<String, dynamic> userData) async {
    return _httpService.post('/users', data: userData);
  }

  Future<HttpResponse> updateUser(String id, Map<String, dynamic> userData) async {
    return _httpService.put('/users/$id', data: userData);
  }

  Future<HttpResponse> deleteUser(String id) async {
    return _httpService.delete('/users/$id');
  }
}
```

### Local DataSource

```dart
import 'dart:convert';
import 'package:base_app/common/services/storage_service.dart';

class UserLocalDataSource {
  const UserLocalDataSource(this._storage);

  final StorageService _storage;
  static const String _userKey = 'user_data';

  Future<void> saveUser(Map<String, dynamic> userData) async {
    await _storage.setString(_userKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final jsonString = await _storage.getString(_userKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  Future<void> deleteUser() async => _storage.remove(_userKey);

  Future<bool> hasUser() async => _storage.containsKey(_userKey);
}
```

### Regras para DataSources

1. **Classe concreta** (não abstrata)
2. **Recebe dependências via construtor** (`HttpService`, `StorageService`)
3. **Retorna dados brutos** (`HttpResponse`, `Map`, `List`)
4. **NÃO trata erros** — deixe propagar para o Repository
5. **NÃO retorna Models/Entities**

---

## Erros tipados

`Result.error(Exception('Failed to get user: $e'))` destrói a informação: o Cubit recebe uma string
e não consegue distinguir sem-rede de `404` de `401`. Sem isso não dá para escolher a mensagem certa
para o usuário, nem disparar refresh de token, nem decidir se cabe um botão de "tentar de novo".

Defina a hierarquia uma vez em `lib/config/error/app_exception.dart`:

```dart
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException(message: $message)';
}

/// Sem conexão, DNS, timeout — a requisição não chegou a ser respondida.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause, super.stackTrace});
}

/// 401/403 — a View deve levar ao login ou pedir novo consentimento.
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.cause, super.stackTrace});
}

/// 404 — recurso inexistente; normalmente vira estado vazio, não erro.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause, super.stackTrace});
}

/// 5xx — falha do servidor; "tentar de novo" faz sentido.
class ServerException extends AppException {
  const ServerException(super.message, {super.cause, super.stackTrace, this.statusCode});
  final int? statusCode;
}

/// Resposta 2xx com corpo fora do contrato esperado.
class ResponseParsingException extends AppException {
  const ResponseParsingException(super.message, {super.cause, super.stackTrace});
}

/// Qualquer coisa não classificada.
class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause, super.stackTrace});
}
```

O Cubit passa a escolher a mensagem pelo tipo, sem inspecionar strings:

```dart
result.when(
  ok: (user) => emit(ProfileLoaded(user: user)),
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
```

> O Cubit não tem `BuildContext`, então ele emite a **causa** (enum ou chave), não o texto.
> A View traduz com `context.l10n` ao renderizar o State de erro.

---

## Criando Repository Implementations

O RepositoryImpl é o único lugar que converte falha em `Result.error`. Ele precisa fazer três coisas
que o template ingênuo esquece: **checar o status HTTP**, **preservar o erro original e o stack trace**
e **classificar** a falha.

### Template Base

```dart
import 'package:base_app/config/error/app_exception.dart';
import 'package:base_app/config/error/result_pattern.dart';
import 'package:base_app/data/datasources/user_remote_datasource.dart';
import 'package:base_app/data/models/user_model.dart';
import 'package:base_app/domain/entities/user_entity.dart';
import 'package:base_app/domain/interfaces/user_repository.dart';

class UserRepositoryImpl with RepositoryErrorMapper implements UserRepository {
  const UserRepositoryImpl(this._remoteDataSource);

  final UserRemoteDataSource _remoteDataSource;

  @override
  Future<Result<UserEntity>> getUserById(String id) async {
    try {
      final response = await _remoteDataSource.getUserById(id);
      ensureSuccess(response); // ✅ 4xx/5xx nunca chega ao fromJson
      final model = UserModel.fromJson(response.data as Map<String, dynamic>);
      return Result.ok(model);
    } catch (error, stackTrace) {
      return Result.error(toAppException(error, stackTrace));
    }
  }

  @override
  Future<Result<List<UserEntity>>> getAllUsers() async {
    try {
      final response = await _remoteDataSource.getUsers();
      ensureSuccess(response);
      final users = (response.data as List<dynamic>)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Result.ok(users);
    } catch (error, stackTrace) {
      return Result.error(toAppException(error, stackTrace));
    }
  }

  @override
  Future<Result<UserEntity>> createUser(UserEntity user) async {
    try {
      final userData = UserModel.fromEntity(user).toJson();
      final response = await _remoteDataSource.createUser(userData);
      ensureSuccess(response);
      final model = UserModel.fromJson(response.data as Map<String, dynamic>);
      return Result.ok(model);
    } catch (error, stackTrace) {
      return Result.error(toAppException(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteUser(String id) async {
    try {
      final response = await _remoteDataSource.deleteUser(id);
      ensureSuccess(response);
      return Result.ok(null);
    } catch (error, stackTrace) {
      return Result.error(toAppException(error, stackTrace));
    }
  }
}
```

### Checagem de status e classificação

Os dois helpers são idênticos em todo RepositoryImpl — mantenha-os num mixin compartilhado:

```dart
mixin RepositoryErrorMapper {
  /// Status fora de 2xx vira exceção tipada antes de qualquer parsing.
  void ensureSuccess(HttpResponse response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return;

    throw switch (status) {
      401 || 403 => UnauthorizedException('Não autorizado ($status)'),
      404 => const NotFoundException('Recurso não encontrado'),
      >= 500 => ServerException('Erro no servidor', statusCode: status),
      _ => UnknownException('Resposta inesperada ($status)'),
    };
  }

  /// Preserva a causa e o stack trace originais em toda conversão.
  AppException toAppException(Object error, StackTrace stackTrace) {
    if (error is AppException) return error;

    // Adapte à exceção do cliente HTTP do projeto (DioException, SocketException, ...).
    if (error is SocketException || error is TimeoutException) {
      return NetworkException('Falha de conexão', cause: error, stackTrace: stackTrace);
    }

    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => NetworkException(
            'Falha de conexão',
            cause: error,
            stackTrace: stackTrace,
          ),
        DioExceptionType.badResponse => UnknownException(
            'Resposta HTTP inválida',
            cause: error,
            stackTrace: stackTrace,
          ),
        _ => UnknownException(
            'Falha inesperada',
            cause: error,
            stackTrace: stackTrace,
          ),
      };
    }

    return UnknownException('Falha inesperada', cause: error, stackTrace: stackTrace);
  }
}
```

> **`catch (e)` sozinho perde o stack trace.** Use sempre `catch (error, stackTrace)` e propague os
> dois — é o que permite ao State de erro registrar a causa real no `BlocObserver` (ver `view-model.md`).

### Parsing grande no DataSource

Quando a resposta contém milhares de itens, faça o parsing fora da thread da UI no próprio DataSource,
usando uma função top-level com `compute()`. Não mova essa decisão para o Cubit ou para a View: o Data Layer
é o ponto que conhece o formato da resposta. Veja o padrão completo em [flutter-isolates](../../flutter-isolates/SKILL.md).

### Repository com Cache (Remote + Local)

```dart
@override
Future<Result<UserEntity>> getUserById(String id) async {
  try {
    final response = await _remoteDataSource.getUserById(id);
    ensureSuccess(response);
    final model = UserModel.fromJson(response.data as Map<String, dynamic>);
    await _localDataSource.saveUser(model.toJson());
    return Result.ok(model);
  } catch (error, stackTrace) {
    final failure = toAppException(error, stackTrace);

    // ✅ Cache só substitui falha de rede. Um 401 ou um corpo inválido
    //    precisam chegar à UI — servir cache aqui esconderia o problema.
    if (failure is! NetworkException) return Result.error(failure);

    try {
      final cachedData = await _localDataSource.getUser();
      if (cachedData != null) return Result.ok(UserModel.fromJson(cachedData));
    } catch (cacheError, cacheStackTrace) {
      // ✅ Falha de cache não sobrescreve a falha original, mas também não some.
      log('Cache indisponível para user $id', error: cacheError, stackTrace: cacheStackTrace);
    }

    return Result.error(failure);
  }
}
```

> `catch (_) {}` vazio é o pior desfecho possível: o app fica sem cache **e** sem registro de por quê.
> Se o erro não muda o fluxo, ele ainda precisa ser logado.

### Regras para Repository Implementations

1. **Implementa a interface do domínio** — `implements UserRepository`
2. **Recebe DataSources via construtor**
3. **SEMPRE envolve em `try/catch (error, stackTrace)`** — nunca `catch (e)` sozinho
4. **Checa o status HTTP antes de fazer parsing** — `ensureSuccess(response)`
5. **Retorna `Result<T>`** — nunca lança exceções
6. **Classifica a falha em `AppException`** preservando causa e stack trace
7. **Converte HttpResponse/Map em Model**

---

## Checklist

### Model:
- [ ] Arquivo em `lib/data/models/<nome>_model.dart`
- [ ] Extende a Entity correspondente
- [ ] `fromJson()` com defaults só em campos opcionais; campo de identidade ausente lança
- [ ] `toJson()` implementado
- [ ] `copyWith()` override retornando Model
- [ ] `fromEntity()` se necessário

### DataSource:
- [ ] Arquivo em `lib/data/datasources/<nome>_<tipo>_datasource.dart`
- [ ] Classe concreta (não abstrata)
- [ ] Recebe `HttpService` ou `StorageService` via construtor
- [ ] Métodos retornam `HttpResponse`, `Map` ou `List`
- [ ] NÃO trata erros

### Repository Implementation:
- [ ] Arquivo em `lib/data/repositories/<nome>_repository_impl.dart`
- [ ] Implementa a interface do domínio
- [ ] Todos os métodos têm `try/catch (error, stackTrace)`
- [ ] `ensureSuccess(response)` antes de qualquer `fromJson`
- [ ] Falha classificada em `AppException`, com `cause` e `stackTrace` preservados
- [ ] Retorna `Result<T>` sempre
- [ ] Convertido para Model em cada método

---

## Erros Comuns

| Erro | Correto |
|---|---|
| `json['id']` sem cast | `json['id'] as String?` e lançar se ausente |
| Default `?? ''` em campo de identidade | Lançar `ResponseParsingException` — default mascara resposta inválida |
| `fromJson` direto, sem olhar o status | `ensureSuccess(response)` antes do parsing |
| DataSource com `try/catch` | DataSource apenas retorna, Repository trata |
| Repository sem `try/catch` | SEMPRE envolva em `try/catch (error, stackTrace)` |
| `catch (e)` sem stack trace | `catch (error, stackTrace)` e propague os dois |
| `Result.error(Exception('falhou: $e'))` | `Result.error(toAppException(error, stackTrace))` |
| `catch (_) {}` vazio no fallback de cache | Logar o erro mesmo quando ele não muda o fluxo |
| `Future<UserEntity>` no Repository | `Future<Result<UserEntity>>` |
