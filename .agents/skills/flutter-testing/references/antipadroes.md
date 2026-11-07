# Anti-padrões: testes que não conseguem falhar

Passe esta lista antes de entregar qualquer suíte. Cada item tem o mesmo defeito de fundo: o teste
continua verde depois de você quebrar a implementação de propósito.

## 1. Verify como única asserção

```dart
// ruim
test('salva o usuário', () async {
  await service.save(user);
  verify(() => repo.save(any())).called(1);
});
```

Passa mesmo se `service.save` gravar o objeto errado, com os campos trocados, ou sem aplicar a regra de
negócio. Prova que houve uma chamada, não que ela estava certa.

```dart
// bom
test('salva o usuário com nome normalizado', () async {
  await service.save(User(name: '  Ana  '));
  final captured = verify(() => repo.save(captureAny())).captured.single as User;
  expect(captured.name, 'Ana');
});
```

Melhor ainda: use um fake em memória e assere o estado final.

## 2. Mock da própria classe sob teste

```dart
// ruim
class MockCartService extends Mock implements CartService {}
test('calcula total', () {
  when(() => service.total()).thenReturn(100);
  expect(service.total(), 100);   // testa o mocktail, não o código
});
```

Mocke as dependências. Nunca o objeto que você está testando.

## 3. findsOneWidget como toda a verificação

```dart
// ruim
testWidgets('renderiza', (tester) async {
  await tester.pumpWidget(wrap(const ProfileScreen()));
  expect(find.byType(ProfileScreen), findsOneWidget);
});
```

Prova que o widget existe — o que já era verdade antes de você escrever a feature. Assere o conteúdo,
o estado e a reação à interação.

## 4. Future.delayed no teste

```dart
// ruim
await tester.tap(find.byKey(const Key('save')));
await Future.delayed(const Duration(seconds: 2));
```

Lento e flaky: em CI carregado, 2s não bastam e o teste quebra sem que nada esteja errado. Use
`fakeAsync` / `async.elapse` em Dart puro e `tester.pump(Duration(...))` em widget test.

## 5. pumpAndSettle em tela com animação infinita

`pumpAndSettle()` espera não haver mais frames agendados. Shimmer, `CircularProgressIndicator`
persistente, `Lottie` em loop e `AnimationController(repeat: true)` nunca param → timeout de 10 minutos.
Nessas telas, avance frames explicitamente.

## 6. Golden regravado para "consertar" a falha

Rodar `flutter test --update-goldens` porque o golden falhou é aceitar a regressão visual sem olhar.
Mostre o diff (o Flutter salva `*_testImage.png`, `*_masterImage.png` e `*_isolatedDiff.png` em
`failures/`) e pergunte se a mudança era intencional.

## 7. Cobertura inflada

Teste de getter, de `toString`, de `copyWith` e de construtor sobe a porcentagem sem testar nada.
Se o objetivo é bater um threshold, exclua o código gerado (`*.g.dart`, `*.freezed.dart`) do cálculo em
vez de escrever teste decorativo.

## 8. Asserção ajustada ao output errado

O padrão mais perigoso, porque o teste fica verde e o bug vai para produção:

```dart
// implementação devolve 1349 por erro de arredondamento
expect(total, 1349);   // asserção "corrigida" para passar
```

Ordem correta de investigação quando um teste falha: a implementação está errada → o critério de aceite
era ambíguo → o teste está errado. Se concluir que era o teste, explique ao usuário por que a
expectativa original era inválida antes de mudar.

## 9. Silenciadores

`skip: true`, `// ignore: ...`, `expect(true, isTrue)`, `try/catch` engolindo a exceção dentro do teste,
`tolerance` afrouxada até passar, `timeout` esticado. Todos transformam falha em silêncio.

## 10. Só o caminho feliz

Toda operação assíncrona tem quatro estados (sucesso, erro, vazio, carregando) e um conjunto de bordas
que agente costuma pular: lista vazia, `null`, timeout, offline, JSON malformado, chamada concorrente,
widget desmontado antes do `await` terminar (`if (!mounted) return`), texto muito longo estourando o
layout, e tela pequena.

## 11. Testes acoplados entre si

Teste que depende da ordem de execução, ou de estado deixado pelo anterior, quebra assim que a suíte
roda em paralelo ou embaralhada. Cada teste monta o próprio mundo no `setUp` e limpa no `tearDown`.
Para conferir: `flutter test --test-randomize-ordering-seed=random`.

## 12. Mock do que não é seu para testar o que não é seu

Mockar `FirebaseFirestore` inteiro para testar que sua query monta o filtro certo testa a sua leitura da
API do Firebase, não o comportamento do app. Coloque uma interface fina sua na frente (`ProductSource`),
teste sua lógica contra ela, e verifique a integração real num integration test.

---

## Checagem rápida antes de entregar

Para cada teste da suíte, responda: **se eu inverter uma condição ou trocar uma constante na
implementação, esse teste fica vermelho?** Se a resposta for não, o teste não está protegendo nada.

Um jeito barato de conferir na prática: quebre de propósito uma linha da implementação, rode
`flutter test`, confirme que falhou, e desfaça. Vale fazer isso nos testes do núcleo de negócio antes de
declarar a feature pronta.
