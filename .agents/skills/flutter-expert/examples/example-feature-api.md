# Exemplo: Feature Completa com API REST

Cenário: listagem e criação de produtos consumindo uma API externa.

**Referências**: `domain.md`, `data.md`, `view-model.md`, `view.md`, `di.md`, `navigation.md`

---

## Estrutura de Arquivos

```
lib/
├── domain/
│   ├── entities/product_entity.dart
│   └── interfaces/product_repository.dart
├── data/
│   ├── models/product_model.dart
│   ├── datasources/product_remote_datasource.dart
│   └── repositories/product_repository_impl.dart
└── presentation/products/
    ├── view/products_view.dart
    ├── view_model/products_cubit.dart
    ├── view_model/products_state.dart
    └── widgets/product_list_item.dart
```

---

## 1. Entity (Domain)

```dart
// lib/domain/entities/product_entity.dart
import 'package:flutter/foundation.dart';

@immutable
class ProductEntity {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final double price;
  final String imageUrl;

  ProductEntity copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductEntity &&
          id == other.id &&
          name == other.name &&
          price == other.price &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => Object.hash(id, name, price, imageUrl);

  @override
  String toString() =>
      'ProductEntity(id: $id, name: $name, price: $price)';
}
```

---

## 2. Repository Interface (Domain)

```dart
// lib/domain/interfaces/product_repository.dart
import 'package:base_app/config/error/result_pattern.dart';
import 'package:base_app/domain/entities/product_entity.dart';

abstract class ProductRepository {
  Future<Result<List<ProductEntity>>> getAll();
  Future<Result<ProductEntity>> create(ProductEntity product);
  Future<Result<void>> delete(String id);
}
```

---

## 3. Model (Data)

```dart
// lib/data/models/product_model.dart
import 'package:base_app/config/error/app_exception.dart';
import 'package:base_app/domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
    required super.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': final String id,
        'name': final String name,
        'price': final num price,
        'image_url': final String imageUrl,
      } => ProductModel(
          id: id,
          name: name,
          price: price.toDouble(),
          imageUrl: imageUrl,
        ),
      _ => throw const ResponseParsingException(
          'ProductModel: campos obrigatórios ausentes ou inválidos',
        ),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_url': imageUrl,
    };
  }

  @override
  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      price: entity.price,
      imageUrl: entity.imageUrl,
    );
  }
}
```

---

## 4. DataSource (Data)

```dart
// lib/data/datasources/product_remote_datasource.dart
import 'package:base_app/common/services/http/http_service.dart';

class ProductRemoteDataSource {
  const ProductRemoteDataSource(this._httpService);

  final HttpService _httpService;

  Future<HttpResponse> getAll() async {
    return _httpService.get('/products');
  }

  Future<HttpResponse> create(Map<String, dynamic> data) async {
    return _httpService.post('/products', data: data);
  }

  Future<HttpResponse> delete(String id) async {
    return _httpService.delete('/products/$id');
  }
}
```

---

## 5. Repository Implementation (Data)

```dart
// lib/data/repositories/product_repository_impl.dart
import 'package:base_app/config/error/app_exception.dart';
import 'package:base_app/config/error/repository_error_mapper.dart';
import 'package:base_app/config/error/result_pattern.dart';
import 'package:base_app/data/datasources/product_remote_datasource.dart';
import 'package:base_app/data/models/product_model.dart';
import 'package:base_app/domain/entities/product_entity.dart';
import 'package:base_app/domain/interfaces/product_repository.dart';

class ProductRepositoryImpl with RepositoryErrorMapper implements ProductRepository {
  const ProductRepositoryImpl(this._dataSource);

  final ProductRemoteDataSource _dataSource;

  @override
  Future<Result<List<ProductEntity>>> getAll() async {
    try {
      final response = await _dataSource.getAll();
      ensureSuccess(response);
      final products = (response.data as List<dynamic>)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Result.ok(products);
    } catch (error, stackTrace) {
      return Result.error(toAppException(error, stackTrace));
    }
  }

  @override
  Future<Result<ProductEntity>> create(ProductEntity product) async {
    try {
      final data = ProductModel.fromEntity(product).toJson();
      final response = await _dataSource.create(data);
      ensureSuccess(response);
      final model = ProductModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return Result.ok(model);
    } catch (error, stackTrace) {
      return Result.error(toAppException(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final response = await _dataSource.delete(id);
      ensureSuccess(response);
      return Result.ok(null);
    } catch (error, stackTrace) {
      return Result.error(toAppException(error, stackTrace));
    }
  }
}
```

> `ensureSuccess` e `toAppException` vêm do mixin `RepositoryErrorMapper` — ver `references/data.md`.
> Sem eles, um `500` com corpo de erro passaria pelo `fromJson` e viraria `Result.ok` com objeto vazio.

---

## 6. State

```dart
// lib/presentation/products/view_model/products_state.dart
import 'package:base_app/domain/entities/product_entity.dart';
import 'package:flutter/foundation.dart';

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

class ProductsDeleting extends ProductsState {
  const ProductsDeleting();

  @override
  String toString() => 'ProductsDeleting';
}

class ProductsError extends ProductsState {
  const ProductsError(this.kind, {this.error});

  /// Causa, não texto — o Cubit não tem context.l10n.
  final ProductsErrorKind kind;
  final Object? error;

  @override
  String toString() => 'ProductsError(kind: $kind, error: $error)';
}

enum ProductsErrorKind { load, create, delete, offline }
```

---

## 7. Cubit

```dart
// lib/presentation/products/view_model/products_cubit.dart
import 'package:base_app/config/error/app_exception.dart';
import 'package:base_app/domain/entities/product_entity.dart';
import 'package:base_app/domain/interfaces/product_repository.dart';
import 'package:base_app/presentation/products/view_model/products_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._repository) : super(const ProductsInitial());

  final ProductRepository _repository;

  Future<void> loadAll() async {
    emit(const ProductsLoading());
    final result = await _repository.getAll();
    result.when(
      ok: (data) => emit(ProductsLoaded(products: data)),
      error: (e) => emit(ProductsError(_kindOf(e, ProductsErrorKind.load), error: e)),
    );
  }

  Future<void> create(ProductEntity product) async {
    emit(const ProductsCreating());
    final result = await _repository.create(product);
    result.when(
      ok: (_) => loadAll(),
      error: (e) => emit(ProductsError(_kindOf(e, ProductsErrorKind.create), error: e)),
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

  ProductsErrorKind _kindOf(Object error, ProductsErrorKind operation) =>
      error is NetworkException ? ProductsErrorKind.offline : operation;
}
```

---

## 8. Widget de Item

```dart
// lib/presentation/products/widgets/product_list_item.dart
import 'package:base_app/domain/entities/product_entity.dart';
import 'package:base_app/l10n/l10n.dart';
import 'package:flutter/material.dart';

class ProductListItem extends StatelessWidget {
  const ProductListItem({
    required this.product,
    required this.onDelete,
    super.key,
  });

  final ProductEntity product;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(product.imageUrl),
      ),
      title: Text(product.name),
      subtitle: Text(l10n.currencyLabel(product.price)),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
    );
  }
}
```

---

## 9. View

```dart
// lib/presentation/products/view/products_view.dart
import 'package:base_app/config/inject/app_injector.dart';
import 'package:base_app/l10n/l10n.dart';
import 'package:base_app/presentation/products/view_model/products_cubit.dart';
import 'package:base_app/presentation/products/view_model/products_state.dart';
import 'package:base_app/presentation/products/widgets/product_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  final _cubit = AppInjector.inject.get<ProductsCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.productsTitle)),
        body: SafeArea(
          top: false,
          child: BlocBuilder<ProductsCubit, ProductsState>(
            builder: (context, state) {
              if (state is ProductsLoading ||
                  state is ProductsCreating ||
                  state is ProductsDeleting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProductsError) {
                // ✅ A View é o único lugar com acesso ao l10n
                return Center(
                  child: Text(switch (state.kind) {
                    ProductsErrorKind.offline => l10n.errorOffline,
                    ProductsErrorKind.load => l10n.errorLoadProducts,
                    ProductsErrorKind.create => l10n.errorCreateProduct,
                    ProductsErrorKind.delete => l10n.errorDeleteProduct,
                  }),
                );
              }
              if (state is ProductsLoaded) {
                // empty-check primeiro (if aninhado) evita bug de ordem
                if (state.products.isEmpty) {
                  return Center(child: Text(context.l10n.emptyProductsLabel));
                }
                return ListView.builder(
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return ProductListItem(
                      key: ValueKey(product.id),
                      product: product,
                      onDelete: () =>
                          context.read<ProductsCubit>().delete(product.id),
                    );
                  },
                );
              }
              // ProductsInitial e estados futuros: branch padrão
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }
}
```

---

## 10. DI

```dart
// lib/config/inject/app_injector.dart

// 4. DataSources
inject.registerLazySingleton<ProductRemoteDataSource>(
  () => ProductRemoteDataSource(inject()),
);

// 5. Repositories
inject.registerLazySingleton<ProductRepository>(
  () => ProductRepositoryImpl(inject()),
);

// 6. Cubits
inject.registerFactory<ProductsCubit>(
  () => ProductsCubit(inject()),
);
```

---

## 11. Rota

```dart
// app_routes.dart
static const String products = '/products';

// app_router.dart
GoRoute(
  path: AppRoutes.products,
  builder: (context, state) => const ProductsView(),
),
```
