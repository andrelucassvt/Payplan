---
name: implement-data
description: Implements the Flutter data layer (Models, DataSources, Repository Implementations) following Clean Architecture. Use whenever creating or modifying files in lib/data/**, implementing an API call, serializing/deserializing JSON, adding a local cache, creating a Repository implementation, or connecting a DataSource to a Repository. Covers Models extending Entity, DataSources returning raw data, and RepositoryImpl with try/catch and Result<T>. Activate even when the user says "call the API", "save to cache", "implement the repository", "parse the JSON response", or "add a data source" without explicitly mentioning Clean Architecture or data layer.
---

# Implement Data Layer — Flutter

## Leitura Rápida

- **Quando criar um Model**: SEMPRE estenda a Entity correspondente, implemente `fromJson()` com defaults, `toJson()`, e `copyWith()` retornando o Model.
- **Quando criar um DataSource**: retorne dados brutos (`HttpResponse`/`Map`/`List`) e NUNCA trate erros — deixe o Repository tratá-los.
- **Quando criar um RepositoryImpl**: SEMPRE envolva em `try/catch`, converta para Model e retorne `Result<T>` — nunca `throw`.
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
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
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
2. **`fromJson()` com valores default** — nunca `json['id']` sem `?? ''`
3. **`toJson()` implementado**
4. **`copyWith()` override retornando Model** (não Entity)
5. **`fromEntity()` quando necessário**

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

## Criando Repository Implementations

### Template Base

```dart
import 'package:base_app/config/error/result_pattern.dart';
import 'package:base_app/domain/entities/user_entity.dart';
import 'package:base_app/domain/interfaces/user_repository.dart';
import 'package:base_app/data/datasources/user_remote_datasource.dart';
import 'package:base_app/data/models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._remoteDataSource);

  final UserRemoteDataSource _remoteDataSource;

  @override
  Future<Result<UserEntity>> getUserById(String id) async {
    try {
      final response = await _remoteDataSource.getUserById(id);
      final model = UserModel.fromJson(response.data as Map<String, dynamic>);
      return Result.ok(model);
    } catch (e) {
      return Result.error(Exception('Failed to get user: $e'));
    }
  }

  @override
  Future<Result<List<UserEntity>>> getAllUsers() async {
    try {
      final response = await _remoteDataSource.getUsers();
      final users = (response.data as List<dynamic>)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Result.ok(users);
    } catch (e) {
      return Result.error(Exception('Failed to get users: $e'));
    }
  }

  @override
  Future<Result<UserEntity>> createUser(UserEntity user) async {
    try {
      final userData = UserModel.fromEntity(user).toJson();
      final response = await _remoteDataSource.createUser(userData);
      final model = UserModel.fromJson(response.data as Map<String, dynamic>);
      return Result.ok(model);
    } catch (e) {
      return Result.error(Exception('Failed to create user: $e'));
    }
  }

  @override
  Future<Result<void>> deleteUser(String id) async {
    try {
      await _remoteDataSource.deleteUser(id);
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception('Failed to delete user: $e'));
    }
  }
}
```

### Repository com Cache (Remote + Local)

```dart
@override
Future<Result<UserEntity>> getUserById(String id) async {
  try {
    final response = await _remoteDataSource.getUserById(id);
    final model = UserModel.fromJson(response.data as Map<String, dynamic>);
    await _localDataSource.saveUser(model.toJson());
    return Result.ok(model);
  } catch (e) {
    try {
      final cachedData = await _localDataSource.getUser();
      if (cachedData != null) {
        return Result.ok(UserModel.fromJson(cachedData));
      }
    } catch (_) {}
    return Result.error(Exception('Failed to get user: $e'));
  }
}
```

### Regras para Repository Implementations

1. **Implementa a interface do domínio** — `implements UserRepository`
2. **Recebe DataSources via construtor**
3. **SEMPRE envolve em `try/catch`**
4. **Retorna `Result<T>`** — nunca lança exceções
5. **Converte HttpResponse/Map em Model**

---

## Checklist

### Model:
- [ ] Arquivo em `lib/data/models/<nome>_model.dart`
- [ ] Extende a Entity correspondente
- [ ] `fromJson()` com defaults (`?? ''`, `?? []`, `?? 0`)
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
- [ ] Todos os métodos têm `try/catch`
- [ ] Retorna `Result<T>` sempre
- [ ] Convertido para Model em cada método

---

## Erros Comuns

| Erro | Correto |
|---|---|
| `json['id']` sem cast/default | `json['id'] as String? ?? ''` |
| DataSource com `try/catch` | DataSource apenas retorna, Repository trata |
| Repository sem `try/catch` | SEMPRE envolva em `try/catch` |
| `Future<UserEntity>` no Repository | `Future<Result<UserEntity>>` |

---

**Última atualização**: 28 de março de 2026
