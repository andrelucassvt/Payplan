# Exemplo: Tela Simples (sem API)

Cenário: tela de contador sem fonte de dados externa.

**Referências**: `view.md`, `view-model.md`, `di.md`, `navigation.md`

---

## Estrutura de Arquivos

```
lib/presentation/counter/
├── view/counter_view.dart
├── view_model/counter_cubit.dart
└── view_model/counter_state.dart
```

---

## 1. State

```dart
// lib/presentation/counter/view_model/counter_state.dart
import 'package:flutter/foundation.dart';

@immutable
sealed class CounterState {
  const CounterState();
}

class CounterInitial extends CounterState {
  const CounterInitial();
}

class CounterLoaded extends CounterState {
  const CounterLoaded({required this.count});
  final int count;
}
```

---

## 2. Cubit

```dart
// lib/presentation/counter/view_model/counter_cubit.dart
import 'package:base_app/presentation/counter/view_model/counter_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(const CounterInitial());

  void increment(int current) => emit(CounterLoaded(count: current + 1));
  void decrement(int current) => emit(CounterLoaded(count: current - 1));
}
```

---

## 3. View

```dart
// lib/presentation/counter/view/counter_view.dart
import 'package:base_app/config/inject/app_injector.dart';
import 'package:base_app/l10n/l10n.dart';
import 'package:base_app/presentation/counter/view_model/counter_cubit.dart';
import 'package:base_app/presentation/counter/view_model/counter_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final _cubit = AppInjector.inject.get<CounterCubit>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.counterTitle)),
        body: SafeArea(
          top: false,
          child: BlocBuilder<CounterCubit, CounterState>(
            builder: (context, state) => switch (state) {
              CounterInitial() => Center(
                  child: ElevatedButton(
                    onPressed: () => _cubit.increment(0),
                    child: Text(context.l10n.startButton),
                  ),
                ),
              CounterLoaded(:final count) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$count', style: Theme.of(context).textTheme.displayLarge),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => context.read<CounterCubit>().decrement(count),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => context.read<CounterCubit>().increment(count),
                          ),
                        ],
                      ),
                    ],
                  ),
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

## 4. Rota

```dart
// lib/config/routes/app_routes.dart
static const String counter = '/counter';

// lib/config/routes/app_router.dart
GoRoute(
  path: AppRoutes.counter,
  builder: (context, state) => const CounterView(),
),
```

---

## 5. DI

```dart
// lib/config/inject/app_injector.dart — seção 6 (Cubits)
inject.registerFactory<CounterCubit>(() => CounterCubit());
```

---

## Checklist

- [x] State: `sealed class` + `@immutable` + `const`
- [x] Cubit: herda `Cubit<CounterState>`, estado inicial no construtor
- [x] View: `StatefulWidget`, `AppInjector`, `BlocProvider.value`, `SafeArea`, `dispose()`
- [x] Rota: constante em `app_routes.dart` + `GoRoute` em `app_router.dart`
- [x] DI: `registerFactory` para o Cubit
