# Receitas de teste por camada

Índice:
- [Dependências de teste](#dependências-de-teste)
- [Unit test em Dart puro](#unit-test-em-dart-puro)
- [Mock com mocktail](#mock-com-mocktail)
- [Tempo, timers e debounce](#tempo-timers-e-debounce)
- [HTTP](#http)
- [Notifier / Bloc / Riverpod](#notifier--bloc--riverpod)
- [Widget test](#widget-test)
- [Golden test](#golden-test)
- [Integration test](#integration-test)
- [Testes tabelados](#testes-tabelados)

## Dependências de teste

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail: ^1.0.4
  fake_async: ^1.3.1
  clock: ^1.1.1
  very_good_analysis: ^7.0.0
```

Adicione `bloc_test` se o projeto usa Bloc, `patrol` se precisa tocar em diálogo nativo (permissão,
webview, notificação) no integration test.

## Unit test em Dart puro

O arquivo não deve importar `package:flutter/material.dart`. Se importar, a lógica está no lugar errado.

```dart
void main() {
  group('CartTotal', () {
    test('soma itens aplicando desconto percentual', () {
      final total = CartTotal.compute(
        items: [Item(price: 1000), Item(price: 500)],
        discountPercent: 10,
      );
      expect(total, 1350);
    });

    test('nunca retorna negativo com desconto acima de 100%', () {
      final total = CartTotal.compute(items: [Item(price: 100)], discountPercent: 150);
      expect(total, 0);
    });

    test('lista vazia retorna zero', () {
      expect(CartTotal.compute(items: [], discountPercent: 10), 0);
    });
  });
}
```

Trabalhe com centavos em `int` para valores monetários. Teste com `double` que espera `expect(total, 13.5)`
falha de forma intermitente por ponto flutuante e o agente "conserta" com `closeTo`, escondendo o bug real.

## Mock com mocktail

```dart
class MockUserRepository extends Mock implements UserRepository {}
class FakeUser extends Fake implements User {}

void main() {
  late MockUserRepository repo;
  late UserService service;

  setUpAll(() => registerFallbackValue(FakeUser()));

  setUp(() {
    repo = MockUserRepository();
    service = UserService(repo);
  });

  test('propaga falha de rede como UserError', () async {
    when(() => repo.fetch(any())).thenThrow(NetworkException());

    final result = await service.load('u1');

    expect(result, isA<UserError>());
    expect((result as UserError).retryable, isTrue);
  });

  test('não chama a rede quando há cache válido', () async {
    when(() => repo.cached(any())).thenReturn(User(id: 'u1'));

    await service.load('u1');

    verifyNever(() => repo.fetch(any()));
  });
}
```

`registerFallbackValue` é obrigatório para qualquer tipo customizado usado em `any()`. Sem ele o teste
falha com mensagem confusa em runtime.

### Fake no lugar de mock, para estado

```dart
class InMemoryTodoRepository implements TodoRepository {
  final _items = <String, Todo>{};
  var failNextWrite = false;

  @override
  Future<void> save(Todo t) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StorageException();
    }
    _items[t.id] = t;
  }

  @override
  Future<List<Todo>> all() async => _items.values.toList();
}
```

Com fake você assere o estado final (`expect(await repo.all(), hasLength(1))`), que é o que importa.
Com mock você só consegue asserir que `save` foi chamado — o que continua verdadeiro mesmo se `save`
estiver gravando o objeto errado.

## Tempo, timers e debounce

Nunca use `await Future.delayed(...)` dentro de teste. Ele torna a suíte lenta e flaky em CI.

```dart
test('debounce dispara uma vez após 300ms', () {
  fakeAsync((async) {
    final search = SearchController(onQuery: calls.add);

    search.type('a');
    search.type('ab');
    search.type('abc');
    async.elapse(const Duration(milliseconds: 299));
    expect(calls, isEmpty);

    async.elapse(const Duration(milliseconds: 1));
    expect(calls, ['abc']);
  });
});
```

Para código que lê a data atual, injete o relógio:

```dart
test('token expirado é detectado', () {
  withClock(Clock.fixed(DateTime.utc(2026, 1, 1)), () {
    final token = Token(expiresAt: DateTime.utc(2025, 12, 31));
    expect(token.isExpired, isTrue);
  });
});
```

## HTTP

Injete o `http.Client` e use o `MockClient` do próprio pacote — mais realista que mockar o repositório,
porque exercita parsing e tratamento de status.

```dart
test('mapeia 401 para SessionExpired', () async {
  final client = MockClient((req) async => http.Response('{"error":"expired"}', 401));
  final api = Api(client: client, baseUrl: 'https://x.test');

  expect(() => api.profile(), throwsA(isA<SessionExpired>()));
});

test('lida com JSON malformado sem crashar', () async {
  final client = MockClient((req) async => http.Response('não é json', 200));
  final api = Api(client: client, baseUrl: 'https://x.test');

  expect(() => api.profile(), throwsA(isA<ParseException>()));
});
```

O segundo teste é o tipo que agente não escreve sozinho e que pega crash real em produção.

## Notifier / Bloc / Riverpod

Teste a sequência de estados, não só o estado final — o intermediário de loading é o que a UI usa.

```dart
// Riverpod
test('emite loading e depois data', () async {
  final container = ProviderContainer(
    overrides: [userRepositoryProvider.overrideWithValue(fakeRepo)],
  );
  addTearDown(container.dispose);

  final states = <AsyncValue<User>>[];
  container.listen(userProvider, (_, next) => states.add(next), fireImmediately: true);

  await container.read(userProvider.future);

  expect(states.first, isA<AsyncLoading>());
  expect(states.last, isA<AsyncData>());
});
```

```dart
// Bloc
blocTest<CartBloc, CartState>(
  'remove item e recalcula total',
  build: () => CartBloc(InMemoryCartRepository()),
  seed: () => CartState(items: [itemA, itemB], total: 1500),
  act: (bloc) => bloc.add(RemoveItem(itemA.id)),
  expect: () => [
    isA<CartState>().having((s) => s.items, 'items', [itemB]).having((s) => s.total, 'total', 500),
  ],
);
```

## Widget test

Sempre teste os quatro estados. Um widget test que só verifica `findsOneWidget` no caminho feliz não
pega nada.

```dart
Widget wrap(Widget child, {List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: Scaffold(body: child)),
    );

testWidgets('mostra mensagem de erro com botão de retry', (tester) async {
  await tester.pumpWidget(wrap(
    const UserScreen(),
    overrides: [userRepositoryProvider.overrideWithValue(FailingRepo())],
  ));
  await tester.pump(); // deixa o future rejeitar

  expect(find.text('Não foi possível carregar'), findsOneWidget);

  await tester.tap(find.byKey(const Key('retry')));
  await tester.pump();

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('estado vazio orienta o usuário', (tester) async {
  await tester.pumpWidget(wrap(const TodoList(items: [])));
  expect(find.text('Nada por aqui ainda'), findsOneWidget);
  expect(find.byType(ListTile), findsNothing);
});
```

Regras práticas:

- `Key` em elementos interativos que o teste precisa alcançar. É mais estável que `find.text`, que quebra
  com tradução.
- `await tester.pump()` avança um frame; `pumpAndSettle()` espera as animações acabarem — e trava para
  sempre se houver shimmer ou loading infinito na tela. Em tela com animação contínua, use
  `pump(Duration(...))` explícito.
- Para overflow de layout em telas pequenas: `tester.view.physicalSize = const Size(320, 568)` com
  `tester.view.devicePixelRatio = 1.0` e `addTearDown` de `resetPhysicalSize`/`resetDevicePixelRatio`.
  Sem fixar o `devicePixelRatio`, o default 3.0 do binding transforma 320×568 físicos em 107×189 lógicos.
- Overflow também aparece com fonte de acessibilidade grande, e essa é a variação que mais escapa:
  repita o teste com `MediaQuery.withClampedTextScaling(minScaleFactor: 2.0, maxScaleFactor: 2.0, ...)`
  no `builder` do `MaterialApp`. Overflow verificado em um único tamanho não conta como verificado.
- Erro de render (RenderFlex overflow) falha o teste por padrão — não silencie com `FlutterError.onError`.

### Item fora da viewport

Para listas longas, role o `Scrollable` até o item antes de interagir:

```dart
await tester.scrollUntilVisible(
  find.byKey(const ValueKey('item_42')),
  300,
  scrollable: find.byType(Scrollable),
);
await tester.tap(find.byKey(const ValueKey('item_42')));
await tester.pump();
```

### Texto ampliado

Combine tamanho físico pequeno e escala alta no mesmo teste. Isso pega layouts que só quebram com Dynamic Type:

```dart
await tester.pumpWidget(
  MediaQuery.withClampedTextScaling(
    minScaleFactor: 2,
    maxScaleFactor: 2,
    child: MaterialApp(home: Scaffold(body: LongListView(items: items))),
  ),
);
expect(tester.takeException(), isNull);
```

## Golden test

Golden é regressão visual, não substituto de asserção de comportamento. Use em componente isolado.

```dart
testWidgets('PrimaryButton — estados', (tester) async {
  await tester.pumpWidget(wrap(const ButtonGallery()));
  await expectLater(
    find.byType(ButtonGallery),
    matchesGoldenFile('goldens/primary_button.png'),
  );
});
```

Cuidados:

- Carregue a fonte real no `flutter_test_config.dart`, senão o golden gerado em CI difere do local
  (o Flutter usa Ahem por padrão em teste).
- Rode golden só em um sistema operacional no CI — antialiasing difere entre plataformas.
- `--update-goldens` é decisão humana. Se o golden falhou, mostre o diff ao usuário e pergunte se a
  mudança visual era intencional.

## Integration test

Só os fluxos que, quebrados, custam dinheiro ou usuários. Cada teste aqui é lento e frágil.

```dart
// integration_test/login_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login completo até a home', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email')), 'user@test.com');
    await tester.enterText(find.byKey(const Key('password')), 'senha123');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_scaffold')), findsOneWidget);
  });
}
```

Rode contra um backend fake ou ambiente de staging determinístico. Integration test que depende de
produção é gerador de falso negativo.

### Execução com `flutter drive`

Quando o projeto exige o fluxo de driver legado, mantenha o entrypoint separado:

```dart
// test_driver/integration_test.dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

O teste continua em `integration_test/`. Execute `flutter drive --driver=test_driver/integration_test.dart
--target=integration_test/login_test.dart -d <device>` apenas em um dispositivo preparado. Para regressões
críticas em múltiplos modelos, configure o mesmo target no Firebase Test Lab; não dependa de produção.

## Testes tabelados

Quando a regra tem muitos casos, tabela em vez de dez testes copiados:

```dart
const cases = [
  (input: '11999999999', expected: '(11) 99999-9999'),
  (input: '1133334444', expected: '(11) 3333-4444'),
  (input: '', expected: ''),
  (input: 'abc', expected: 'abc'),
];

for (final c in cases) {
  test('formata "${c.input}"', () {
    expect(formatPhone(c.input), c.expected);
  });
}
```
