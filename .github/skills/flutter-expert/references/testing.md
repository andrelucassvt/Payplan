# Testing — Flutter

## Leitura Rápida

- **Quando testar um Cubit**: use `blocTest<Cubit, State>()` — nunca instancie o Cubit e cheque `cubit.state` diretamente.
- **Quando testar um RepositoryImpl**: crie um `FakeDataSource` concreto — nunca use mocks para datasources simples.
- **Quando testar um widget**: use `pumpWidget` + `find` + `expect`; envolva com `MaterialApp` e `BlocProvider` se necessário.
- **Quando usar mocks**: somente quando o `Fake` cresce além de ~30 linhas ou exige muitas dependências encadeadas.
- **Assertions**: prefira `package:checks` (`check(value).equals(...)`) sobre `expect(value, matcher)`.
- **Estrutura de todos os testes**: Arrange → Act → Assert (ou Given / When / Then) sem exceção.

---

## Estrutura

```
test/
├── presentation/
│   └── <feature>/
│       ├── <feature>_cubit_test.dart
│       └── <feature>_view_test.dart
├── data/
│   └── <feature>/
│       ├── <feature>_repository_impl_test.dart
│       └── fakes/
│           └── fake_<feature>_datasource.dart
└── domain/
    └── <feature>/
        └── <feature>_entity_test.dart
```

---

## Testando Cubits com blocTest

### Padrão base

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base_app/presentation/profile/view_model/profile_cubit.dart';
import 'package:base_app/presentation/profile/view_model/profile_state.dart';

import 'fakes/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeProfileRepository();
  });

  group('ProfileCubit', () {
    blocTest<ProfileCubit, ProfileState>(
      'loadProfile_whenRepositorySucceeds_emitsLoadedState',
      build: () => ProfileCubit(fakeRepository),
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>(),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'loadProfile_whenRepositoryFails_emitsErrorState',
      build: () => ProfileCubit(fakeRepository..shouldFail = true),
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>(),
      ],
    );
  });
}
```

### Verificando dados no estado

```dart
blocTest<ProfileCubit, ProfileState>(
  'loadProfile_whenRepositorySucceeds_emitsUserName',
  build: () => ProfileCubit(fakeRepository),
  act: (cubit) => cubit.loadProfile(),
  expect: () => [
    isA<ProfileLoading>(),
    isA<ProfileLoaded>().having((s) => s.name, 'name', 'André'),
  ],
);
```

### Verificando efeitos colaterais com verify

```dart
blocTest<ProfileCubit, ProfileState>(
  'saveProfile_callsRepositoryOnce',
  build: () => ProfileCubit(fakeRepository),
  act: (cubit) => cubit.saveProfile(name: 'André'),
  verify: (_) {
    check(fakeRepository.saveCallCount).equals(1);
  },
);
```

---

## Fakes (preferidos sobre mocks)

### FakeRepository

```dart
// test/presentation/profile/fakes/fake_profile_repository.dart
import 'package:base_app/config/error/result_pattern.dart';
import 'package:base_app/domain/entities/profile_entity.dart';
import 'package:base_app/domain/interfaces/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  bool shouldFail = false;
  int saveCallCount = 0;

  @override
  Future<Result<ProfileEntity>> getProfile() async {
    if (shouldFail) return Result.error(Exception('fake error'));
    return Result.ok(const ProfileEntity(name: 'André', email: 'test@test.com'));
  }

  @override
  Future<Result<void>> saveProfile(ProfileEntity profile) async {
    saveCallCount++;
    if (shouldFail) return Result.error(Exception('fake error'));
    return Result.ok(null);
  }
}
```

### FakeDataSource

```dart
// test/data/profile/fakes/fake_profile_remote_datasource.dart
class FakeProfileRemoteDataSource {
  bool shouldThrow = false;

  Future<Map<String, dynamic>> getProfile() async {
    if (shouldThrow) throw Exception('network error');
    return {'name': 'André', 'email': 'test@test.com'};
  }
}
```

---

## Testando RepositoryImpl

```dart
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base_app/data/repositories/profile_repository_impl.dart';

import 'fakes/fake_profile_remote_datasource.dart';

void main() {
  late FakeProfileRemoteDataSource fakeDatasource;
  late ProfileRepositoryImpl repository;

  setUp(() {
    fakeDatasource = FakeProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(fakeDatasource);
  });

  group('ProfileRepositoryImpl', () {
    test('getProfile_whenDatasourceSucceeds_returnsOk', () async {
      final result = await repository.getProfile();
      check(result.isOk).isTrue();
    });

    test('getProfile_whenDatasourceThrows_returnsError', () async {
      fakeDatasource.shouldThrow = true;
      final result = await repository.getProfile();
      check(result.isError).isTrue();
    });
  });
}
```

---

## Testando Widgets

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:base_app/presentation/profile/view/profile_view.dart';
import 'package:base_app/presentation/profile/view_model/profile_cubit.dart';
import 'package:base_app/presentation/profile/view_model/profile_state.dart';

class MockProfileCubit extends MockCubit<ProfileState> implements ProfileCubit {}

void main() {
  late MockProfileCubit mockCubit;

  setUp(() {
    mockCubit = MockProfileCubit();
  });

  testWidgets('profileView_whenLoaded_showsUserName', (tester) async {
    when(() => mockCubit.state).thenReturn(
      const ProfileLoaded(name: 'André', email: 'test@test.com'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ProfileCubit>.value(
          value: mockCubit,
          child: const ProfileView(),
        ),
      ),
    );

    expect(find.text('André'), findsOneWidget);
  });

  testWidgets('profileView_whenLoading_showsProgressIndicator', (tester) async {
    when(() => mockCubit.state).thenReturn(const ProfileLoading());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ProfileCubit>.value(
          value: mockCubit,
          child: const ProfileView(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

---

## Regras Obrigatórias

1. **`blocTest` para Cubits** — nunca cheque `cubit.state` diretamente
2. **Fakes sobre mocks** — use `MockCubit` do `bloc_test` somente em testes de widget
3. **AAA obrigatório** — Arrange no `setUp`/`build`, Act no `act`/`test body`, Assert no `expect`/`verify`
4. **`package:checks`** — use `check(value).equals(x)` em vez de `expect(value, equals(x))`
5. **Naming**: `<método>_<cenário>_<resultado>` — ex.: `loadProfile_whenFails_emitsError`
6. **Um comportamento por teste** — não combine loading + loaded + verify na mesma asserção
7. **`setUp` para instâncias** — nunca instancie fakes inline dentro do `blocTest`

---

## Checklist

### Cubit:
- [ ] Arquivo em `test/presentation/<feature>/<feature>_cubit_test.dart`
- [ ] Usa `blocTest<XCubit, XState>`
- [ ] Fake do repository criado em `fakes/`
- [ ] Cobre: sucesso, falha e (se houver) estado intermediário
- [ ] Nomes seguem o padrão `<método>_<cenário>_<resultado>`

### RepositoryImpl:
- [ ] Arquivo em `test/data/<feature>/<feature>_repository_impl_test.dart`
- [ ] Fake do datasource criado em `fakes/`
- [ ] Cobre: caminho feliz + exceção do datasource

### Widget:
- [ ] Arquivo em `test/presentation/<feature>/<feature>_view_test.dart`
- [ ] Usa `MockCubit` com `when(() => mockCubit.state).thenReturn(...)`
- [ ] `pumpWidget` envolto em `MaterialApp` + `BlocProvider`
- [ ] Cobre estados visuais principais (loading, loaded, error)

---

## Erros Comuns

| Erro | Correto |
|---|---|
| `expect(cubit.state, isA<XLoaded>())` | `blocTest(..., expect: () => [isA<XLoaded>()])` |
| Mock do Repository em teste de Cubit | `FakeRepository` concreto |
| `expect(result, equals(true))` | `check(result).isTrue()` |
| Instanciar Fake dentro do `blocTest.build` | Instanciar no `setUp` e referenciar no `build` |
| Testar múltiplos comportamentos em um `blocTest` | Um `blocTest` por comportamento |
| Widget sem `BlocProvider` | Sempre envolva com `BlocProvider<XCubit>.value(value: mockCubit)` |

---

## Referências

- [`bloc_test`](https://pub.dev/packages/bloc_test) — `blocTest`, `MockBloc`, `MockCubit`, `whenListen`
- [`package:checks`](https://pub.dev/packages/checks) — assertions modernas que substituem matchers do `flutter_test`
- [`mocktail`](https://pub.dev/packages/mocktail) — mocking sem geração de código; use apenas para widget tests
- [`flutter_test`](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html) — `pumpWidget`, `find`, `tester`, `testWidgets`
- [Bloc Testing Guide](https://bloclibrary.dev/testing/) — documentação oficial de testes com bloc_test
