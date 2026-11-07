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
      build: () => ProfileCubit(
        fakeRepository..failure = const UnknownException('falha'),
      ),
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
  /// Falha a ser devolvida; `null` = caminho feliz.
  /// Tipada, para o teste conseguir cobrir cada ramo de erro do Cubit.
  AppException? failure;
  int saveCallCount = 0;

  @override
  Future<Result<ProfileEntity>> getProfile() async {
    if (failure != null) return Result.error(failure!);
    return Result.ok(const ProfileEntity(name: 'André', email: 'test@test.com'));
  }

  @override
  Future<Result<void>> saveProfile(ProfileEntity profile) async {
    saveCallCount++;
    if (failure != null) return Result.error(failure!);
    return Result.ok(null);
  }
}
```

Um `bool shouldFail` só permite testar "deu erro". Com a falha tipada dá para verificar que o Cubit
escolhe a causa certa para cada tipo:

```dart
blocTest<ProfileCubit, ProfileState>(
  'loadProfile_whenOffline_emitsOfflineError',
  build: () => ProfileCubit(fakeRepository..failure = const NetworkException('sem rede')),
  act: (cubit) => cubit.loadProfile(),
  expect: () => [
    isA<ProfileLoading>(),
    isA<ProfileError>().having((s) => s.kind, 'kind', ProfileErrorKind.offline),
  ],
);
```

### FakeDataSource

O fake precisa devolver **o mesmo tipo do DataSource real** (`HttpResponse`), senão o
RepositoryImpl — que faz `response.data as Map` e `ensureSuccess(response)` — não compila
contra ele. Exponha o status para conseguir testar os caminhos de erro tipado:

```dart
// test/data/profile/fakes/fake_profile_remote_datasource.dart
import 'package:base_app/common/services/http/http_service.dart';
import 'package:base_app/data/datasources/profile_remote_datasource.dart';

class FakeProfileRemoteDataSource implements ProfileRemoteDataSource {
  bool shouldThrow = false;
  int statusCode = 200;
  Object? data = const {'id': '1', 'name': 'André', 'email': 'test@test.com'};

  @override
  Future<HttpResponse> getProfile() async {
    if (shouldThrow) throw const SocketException('network error');
    return HttpResponse(statusCode: statusCode, data: data);
  }
}
```

Com isso os três cenários que importam ficam testáveis:

```dart
test('getProfile_whenServerReturns500_returnsServerException', () async {
  fakeDatasource.statusCode = 500;

  final result = await repository.getProfile();

  check(result.isError).isTrue();
  check((result as Error).error).isA<ServerException>();
});

test('getProfile_whenBodyMissesId_returnsParsingException', () async {
  fakeDatasource.data = const {'name': 'André'}; // sem "id"

  final result = await repository.getProfile();

  check((result as Error).error).isA<ResponseParsingException>();
});

test('getProfile_whenSocketFails_returnsNetworkException', () async {
  fakeDatasource.shouldThrow = true;

  final result = await repository.getProfile();

  check((result as Error).error).isA<NetworkException>();
});
```

> O `implements ProfileRemoteDataSource` no fake não é decorativo: é ele que faz o teste
> quebrar quando a assinatura do DataSource real muda.

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

### O mock precisa entrar pelo AppInjector, não por um BlocProvider externo

A View resolve o próprio Cubit no service locator (`final _cubit = AppInjector.inject.get<ProfileCubit>()`)
e cria o `BlocProvider.value` dela mesma — ver `view.md`. Portanto:

```dart
// ❌ NÃO funciona: a View ignora este provider e vai ao GetIt,
//    que está vazio no teste → StateError antes do primeiro expect.
await tester.pumpWidget(
  MaterialApp(
    home: BlocProvider<ProfileCubit>.value(value: mockCubit, child: const ProfileView()),
  ),
);
```

Substitua o Cubit **no injector**, que é por onde a View realmente o obtém:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:base_app/config/inject/app_injector.dart';
import 'package:base_app/presentation/profile/view/profile_view.dart';
import 'package:base_app/presentation/profile/view_model/profile_cubit.dart';
import 'package:base_app/presentation/profile/view_model/profile_state.dart';

class MockProfileCubit extends MockCubit<ProfileState> implements ProfileCubit {}

void main() {
  late MockProfileCubit mockCubit;

  setUp(() {
    mockCubit = MockProfileCubit();

    // ✅ A View chama loadProfile() no initState. Sem stub, mocktail
    //    lança MissingStubError e o teste morre no primeiro pump.
    when(() => mockCubit.loadProfile()).thenAnswer((_) async {});

    AppInjector.inject.registerFactory<ProfileCubit>(() => mockCubit);
  });

  tearDown(() async {
    await AppInjector.inject.reset();
  });

  Future<void> pumpProfileView(
    WidgetTester tester,
    ProfileState state, {
    double textScale = 1.0,
  }) async {
    when(() => mockCubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: child!,
        ),
        home: const ProfileView(),
      ),
    );
  }

  testWidgets('profileView_whenLoaded_showsUserName', (tester) async {
    await pumpProfileView(
      tester,
      const ProfileLoaded(name: 'André', email: 'test@test.com'),
    );

    expect(find.text('André'), findsOneWidget);
  });

  testWidgets('profileView_whenLoading_showsProgressIndicator', (tester) async {
    await pumpProfileView(tester, const ProfileLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // ⚠️ O binding de teste roda em 800×600 lógicos — tamanho em que quase nada
  //    estoura. Um único teste de overflow nesse default dá falsa segurança:
  //    verifique tela estreita E fonte ampliada.
  testWidgets('profileView_whenNarrowScreen_hasNoOverflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568); // iPhone SE
    tester.view.devicePixelRatio = 1.0; // sem isso o default 3.0 vira 107×189
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpProfileView(
      tester,
      const ProfileLoaded(name: 'André', email: 'test@test.com'),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('profileView_whenLargeTextScale_hasNoOverflow', (tester) async {
    await pumpProfileView(
      tester,
      const ProfileLoaded(name: 'André', email: 'test@test.com'),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
  });
}
```

Pontos que quebram testes de View e não são óbvios:

- **Stub de todo método chamado no `initState`.** `MockCubit` cobre `state`, `stream` e `close`;
  qualquer método do seu Cubit precisa de `when(...)` explícito.
- **`reset()` do GetIt é assíncrono** — `await` no `tearDown`, senão o registro vaza para o próximo teste.
- **A View chama `_cubit.close()` no `dispose`.** O `MockCubit` aceita, mas se você reaproveitar a
  mesma instância entre testes depois de um `pumpWidget`, ela já foi fechada — recrie no `setUp`.
- **Para testar transição de estado** (loading → loaded), use `whenListen(mockCubit, Stream.fromIterable([...]), initialState: ...)`
  em vez de trocar o retorno de `state` manualmente.

> Se preferir manter os testes de View independentes do GetIt, a alternativa é a View aceitar um
> Cubit opcional (`ProfileView({super.key, @visibleForTesting this.cubit})` com
> `final _cubit = widget.cubit ?? AppInjector.inject.get<ProfileCubit>()`). Escolha **um** dos dois
> padrões e aplique em todas as Views — o que não funciona é testar como se a View aceitasse
> injeção externa quando ela não aceita.

---

## Regras Obrigatórias

1. **`blocTest` para Cubits** — nunca cheque `cubit.state` diretamente
2. **Fakes sobre mocks** — use `MockCubit` do `bloc_test` somente em testes de widget
3. **AAA obrigatório** — Arrange no `setUp`/`build`, Act no `act`/`test body`, Assert no `expect`/`verify`
4. **`package:checks`** — use `check(value).equals(x)` em vez de `expect(value, equals(x))`
5. **Naming**: `<método>_<cenário>_<resultado>` — ex.: `loadProfile_whenFails_emitsError`
6. **Um comportamento por teste** — não combine loading + loaded + verify na mesma asserção
7. **`setUp` para instâncias** — nunca instancie fakes inline dentro do `blocTest`
8. **Overflow em widgets** — após `pumpWidget`, verifique com `expect(tester.takeException(), isNull)` em
   **mais de um tamanho**: tela estreita (`tester.view.physicalSize`) e `textScaler` ampliado
   (`MediaQuery.withClampedTextScaling`). Um único teste no default 800×600 não pega overflow real

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
- [ ] Mock registrado no `AppInjector` (é de lá que a View resolve o Cubit)
- [ ] Métodos chamados no `initState` estão stubados
- [ ] `await AppInjector.inject.reset()` no `tearDown`
- [ ] Cobre estados visuais principais (loading, loaded, error)
- [ ] Verifica overflow com `expect(tester.takeException(), isNull)` em tela estreita (320×568) **e**
      com `textScale` 2.0 — não apenas no default 800×600 do binding

---

## Erros Comuns

| Erro | Correto |
|---|---|
| `expect(cubit.state, isA<XLoaded>())` | `blocTest(..., expect: () => [isA<XLoaded>()])` |
| Mock do Repository em teste de Cubit | `FakeRepository` concreto |
| `expect(result, equals(true))` | `check(result).isTrue()` |
| Instanciar Fake dentro do `blocTest.build` | Instanciar no `setUp` e referenciar no `build` |
| Testar múltiplos comportamentos em um `blocTest` | Um `blocTest` por comportamento |
| Passar o mock por `BlocProvider.value` externo | Registrar no `AppInjector` — a View resolve de lá |
| Fake do DataSource retornando `Map` | Retornar `HttpResponse` e `implements` o DataSource real |
| Esquecer `await` no `AppInjector.inject.reset()` | `reset()` é assíncrono; sem `await` o registro vaza |
| Método do `initState` sem stub | `when(() => mockCubit.loadX()).thenAnswer((_) async {})` |

---

## Referências

- [`bloc_test`](https://pub.dev/packages/bloc_test) — `blocTest`, `MockBloc`, `MockCubit`, `whenListen`
- [`package:checks`](https://pub.dev/packages/checks) — assertions modernas que substituem matchers do `flutter_test`
- [`mocktail`](https://pub.dev/packages/mocktail) — mocking sem geração de código; use quando um fake ficar maior que o comportamento isolado que precisa ser controlado. A estratégia geral e as receitas estão em [`flutter-testing`](../../flutter-testing/SKILL.md)
- [`flutter_test`](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html) — `pumpWidget`, `find`, `tester`, `testWidgets`
- [Bloc Testing Guide](https://bloclibrary.dev/testing/) — documentação oficial de testes com bloc_test
