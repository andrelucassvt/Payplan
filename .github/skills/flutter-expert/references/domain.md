# Domain Layer — Flutter

## Leitura Rápida

- **Quando criar uma Entity**: SEMPRE adicione `@immutable`, construtor `const`, propriedades `final`, `copyWith()`, `==` e `hashCode`.
- **Quando criar uma Repository Interface**: SEMPRE use `abstract class`, retorne `Future<Result<T>>` em todos os métodos, use Entities (nunca Models) nos parâmetros e retornos.
- **Quando adicionar imports no domain**: NUNCA importe Dio, SharedPreferences, UI ou classes de serialização JSON.
- **Quando comparar listas em Entity**: use `listEquals` do `package:flutter/foundation.dart`.

---

## Estrutura

```
lib/domain/
├── entities/
│   ├── user_entity.dart
│   ├── product_entity.dart
│   └── home_entity.dart
└── interfaces/
    ├── user_repository.dart
    ├── product_repository.dart
    └── home_repository.dart
```

**Nomenclatura:**
- Entities: `<nome>_entity.dart`
- Interfaces: `<nome>_repository.dart`

---

## Criando Entities

### Template Base

```dart
import 'package:flutter/foundation.dart';

@immutable
class UserEntity {
  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          id == other.id &&
          name == other.name &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, name, email);

  @override
  String toString() => 'UserEntity(id: $id, name: $name, email: $email)';
}
```

> **Não inclua `runtimeType == other.runtimeType` no `==`.** Models estendem Entities
> (`class UserModel extends UserEntity`), então a checagem de `runtimeType` faz
> `UserModel(id: '1') != UserEntity(id: '1')`. Como o Repository retorna Models tipados como
> Entities, isso quebra qualquer asserção de teste que compare com uma Entity literal.
> O `other is UserEntity` já garante a segurança de tipo necessária.

### Regras Obrigatórias para Entities

1. `@immutable` — SEMPRE adicione
2. `const` constructor
3. `final` em todos os campos
4. `copyWith()` — SEMPRE implemente
5. `==` e `hashCode` — SEMPRE implemente, sempre sobre os mesmos campos
6. `toString()` — recomendado para debugging

---

## Entity com Lista

```dart
import 'package:flutter/foundation.dart';

@immutable
class HomeEntity {
  const HomeEntity({
    required this.message,
    required this.items,
  });

  final String message;
  final List<String> items;

  HomeEntity copyWith({String? message, List<String>? items}) {
    return HomeEntity(
      message: message ?? this.message,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeEntity &&
          message == other.message &&
          listEquals(items, other.items);  // ✅ Use listEquals

  @override
  int get hashCode => Object.hash(message, Object.hashAll(items));  // ✅ Use hashAll
}
```

> **`Object.hash(message, items)` está errado** quando `items` é uma `List`. O `hashCode` de uma
> lista é por identidade, então duas `HomeEntity` consideradas iguais por `listEquals` produziriam
> hashes diferentes — violando o contrato `==`/`hashCode` e quebrando `Set`, chaves de `Map` e
> `distinct()`. Sempre que o `==` usar `listEquals`, o `hashCode` precisa usar `Object.hashAll`.
>
> A mesma regra vale para `Map` e `Set` em campos: `mapEquals`/`setEquals` no `==` exigem
> `Object.hashAll` sobre as entradas no `hashCode`.

## Entity com Composição

```dart
@immutable
class UserEntity {
  const UserEntity({
    required this.id,
    required this.name,
    required this.address,  // ✅ Entity composta
  });

  final String id;
  final String name;
  final AddressEntity address;

  UserEntity copyWith({String? id, String? name, AddressEntity? address}) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          id == other.id &&
          name == other.name &&
          address == other.address;  // ✅ Compara entity interna

  @override
  int get hashCode => Object.hash(id, name, address);
}
```

---

## Criando Repository Interfaces

### Template Base

```dart
import 'package:base_app/config/error/result_pattern.dart';
import 'package:base_app/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<Result<UserEntity>> getUserById(String id);
  Future<Result<List<UserEntity>>> getAllUsers();
  Future<Result<UserEntity>> createUser(UserEntity user);
  Future<Result<UserEntity>> updateUser(UserEntity user);
  Future<Result<void>> deleteUser(String id);
}
```

### Repository com Paginação

```dart
@immutable
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });

  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
}

abstract class ProductRepository {
  Future<Result<PageResult<ProductEntity>>> getProductsPaginated({
    required int page,
    required int pageSize,
  });
}
```

### Regras para Repository Interfaces

1. **Sempre `abstract class`**
2. **Sempre retorna `Future<Result<T>>`**
3. **Usa Entities** (não Models) nos parâmetros e retornos
4. **Sem implementação** — apenas assinaturas
5. **Sem dependências de infra** — apenas imports de domain e result_pattern

---

## Checklist

### Entity:
- [ ] Arquivo em `lib/domain/entities/<nome>_entity.dart`
- [ ] `@immutable`
- [ ] Construtor `const`
- [ ] Propriedades `final`
- [ ] `copyWith()`
- [ ] `==` e `hashCode` sobre os mesmos campos
- [ ] `toString()` (recomendado)
- [ ] `listEquals` no `==` **e** `Object.hashAll` no `hashCode` para listas
- [ ] `==` sem `runtimeType` (Models estendem Entities)

### Repository Interface:
- [ ] Arquivo em `lib/domain/interfaces/<nome>_repository.dart`
- [ ] Classe `abstract`
- [ ] Todos os métodos retornam `Future<Result<T>>`
- [ ] Usa Entities (não Models)
- [ ] Import do `result_pattern.dart`

---

## Erros Comuns

| Erro | Correto |
|---|---|
| `String name;` sem `final` | `final String name;` |
| Sem `@immutable` e `const` | `@immutable class X { const X({required this.name}); }` |
| Sem `copyWith()` | Implementar com `X? name` e `name ?? this.name` |
| `Future<UserModel> getUser()` | `Future<Result<UserEntity>> getUser()` |
| `import 'package:dio/dio.dart'` no domain | Apenas `flutter/foundation.dart` e imports do próprio projeto |
| Repository sem `Result<T>` — lança exceções | `Future<Result<UserEntity>> getUser(String id)` |
| `Object.hash(msg, items)` com `items` sendo `List` | `Object.hash(msg, Object.hashAll(items))` |
| `runtimeType == other.runtimeType` no `==` | Só `other is UserEntity` — senão Model nunca é igual a Entity |
| `==` compara 5 campos e `hashCode` usa 3 | Ambos sobre exatamente os mesmos campos |
