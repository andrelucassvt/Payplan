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
          runtimeType == other.runtimeType &&
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
import 'package:base_app/domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
    required super.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String? ?? '',
    );
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
import 'package:base_app/config/error/result_pattern.dart';
import 'package:base_app/data/datasources/product_remote_datasource.dart';
import 'package:base_app/data/models/product_model.dart';
import 'package:base_app/domain/entities/product_entity.dart';
import 'package:base_app/domain/interfaces/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._dataSource);

  final ProductRemoteDataSource _dataSource;

  @override
  Future<Result<List<ProductEntity>>> getAll() async {
    try {
      final response = await _dataSource.getAll();
      final products = (response.data as List<dynamic>)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Result.ok(products);
    } catch (e) {
      return Result.error(Exception('Erro ao buscar produtos: $e'));
    }
  }

  @override
  Future<Result<ProductEntity>> create(ProductEntity product) async {
    try {
      final data = ProductModel.fromEntity(product).toJson();
      final response = await _dataSource.create(data);
      final model = ProductModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return Result.ok(model);
    } catch (e) {
      return Result.error(Exception('Erro ao criar produto: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _dataSource.delete(id);
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception('Erro ao deletar produto: $e'));
    }
  }
}
```

---

## 6. State

```dart
// lib/presentation/products/view_model/products_state.dart
import 'package:base_app/domain/entities/product_entity.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class ProductsState {
  const ProductsState();
}

class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

class ProductsLoaded extends ProductsState {
  const ProductsLoaded({required this.products});
  final List<ProductEntity> products;
}

class ProductsCreating extends ProductsState {
  const ProductsCreating();
}

class ProductsDeleting extends ProductsState {
  const ProductsDeleting();
}

class ProductsError extends ProductsState {
  const ProductsError(this.message);
  final String message;
}
```

---

## 7. Cubit

```dart
// lib/presentation/products/view_model/products_cubit.dart
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
      error: (e) => emit(ProductsError('Erro ao carregar produtos')),
    );
  }

  Future<void> create(ProductEntity product) async {
    emit(const ProductsCreating());
    final result = await _repository.create(product);
    result.when(
      ok: (_) => loadAll(),
      error: (e) => emit(ProductsError('Erro ao criar produto')),
    );
  }

  Future<void> delete(String id) async {
    emit(const ProductsDeleting());
    final result = await _repository.delete(id);
    result.when(
      ok: (_) => loadAll(),
      error: (e) => emit(ProductsError('Erro ao deletar produto')),
    );
  }
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
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.productsTitle)),
        body: SafeArea(
          top: false,
          child: BlocBuilder<ProductsCubit, ProductsState>(
            builder: (context, state) => switch (state) {
              ProductsInitial() => const SizedBox.shrink(),
              ProductsLoading() ||
              ProductsCreating() ||
              ProductsDeleting() =>
                const Center(child: CircularProgressIndicator()),
              ProductsError(:final message) =>
                Center(child: Text(message)),
              ProductsLoaded(:final products) when products.isEmpty =>
                Center(child: Text(context.l10n.emptyProductsLabel)),
              ProductsLoaded(:final products) => ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductListItem(
                      key: ValueKey(product.id),
                      product: product,
                      onDelete: () =>
                          context.read<ProductsCubit>().delete(product.id),
                    );
                  },
                ),
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
