# Regras de teste — colar no CLAUDE.md do projeto

Este bloco carrega em toda sessão, então fica curto de propósito. A skill `flutter-testing` tem o
detalhe; aqui ficam só as proibições que precisam estar sempre em contexto.

---

## Testes

**Antes de implementar:** escreva os critérios de aceite (incluindo caminhos de erro) e confirme comigo.
Depois escreva o teste falhando. Só então a implementação.

**Antes de dizer "pronto":** rode `./scripts/check.sh` e mostre a saída. Sem isso, a feature não está
pronta — está escrita.

**E antes disso, no núcleo de negócio:** quebre uma linha da implementação de propósito, confirme que o
teste fica vermelho, desfaça. Teste que continua verde com a implementação quebrada não protege nada.

**Quando um teste falhar**, investigue nesta ordem: a implementação está errada → o critério de aceite
era ambíguo → o teste está errado. Se concluir que o teste é que está errado, pare e me explique por que
a expectativa original era inválida antes de alterar qualquer asserção.

**Proibido para fazer a suíte passar:**
- alterar a asserção para casar com o output atual
- `skip: true`, `// ignore:`, `expect(true, isTrue)`, remover teste
- `flutter test --update-goldens` (regravar golden é decisão minha — mostre o diff)
- baixar o threshold de cobertura
- `await Future.delayed(...)` dentro de teste (use `fakeAsync` ou `tester.pump(Duration(...))`)

**Ao escrever teste:**
- `mocktail`, nunca `mockito` (codegen quebra)
- fake em memória em vez de mock, quando o que importa é estado
- `verify(...).called(1)` nunca como única asserção
- cubra os quatro estados: sucesso, erro, vazio, carregando
- cubra as bordas: lista vazia, null, timeout, offline, JSON malformado, widget desmontado durante await
- nada de I/O real, `DateTime.now()` ou `Random()` sem injeção

**Me avise explicitamente** — não trate como coberto pela suíte — ao mexer em: `pubspec.yaml`
(dependência nova), permissões do Android/iOS, auth/cripto/storage de token, migrations de banco local,
ou endpoint novo.
