# Montando o gauntlet

O cerco automatizado que decide se o código do agente passa. Objetivo: nenhuma implementação quebrada
consegue chegar ao merge sem que alguém tenha lido a saída vermelha.

Índice:
- [Ordem de execução](#ordem-de-execução)
- [Análise estática](#análise-estática)
- [Cobertura com threshold](#cobertura-com-threshold)
- [Métricas de código](#métricas-de-código)
- [Mutation testing](#mutation-testing)
- [Teste flaky](#teste-flaky)
- [CI](#ci)
- [Instalando num projeto existente](#instalando-num-projeto-existente)

## Ordem de execução

Do mais barato para o mais caro — falha cedo economiza minutos por rodada:

1. `dart format --set-exit-if-changed lib test`
2. `dart fix --dry-run` e, com decisão explícita, `dart fix --apply`
3. `flutter analyze --fatal-infos --fatal-warnings`
4. `flutter test --coverage`
5. threshold de cobertura
6. métricas (complexidade, dependências não usadas)
7. integration test (só no CI, ou antes de release)

`assets/check.sh` faz de 1 a 5.

## Análise estática

`assets/analysis_options.yaml` traz a configuração pronta. As promoções a `error` que mais importam:

- **`unawaited_futures`** — `Future` sem `await` é a fonte mais comum de bug silencioso em código gerado:
  a operação parece ter acontecido, o estado atualiza fora de ordem, e o teste passa por sorte de timing.
- **`avoid_dynamic_calls`** — chamada em `dynamic` só quebra em runtime, quase sempre no dispositivo do
  usuário.
- **`missing_required_param`**, **`invalid_use_of_protected_member`** — em Flutter, warning aqui vira
  crash.
- **`use_build_context_synchronously`** — usar `context` depois de um `await` sem checar `mounted` é
  crash clássico pós-navegação.

Exclua sempre código gerado (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) do analyzer e da cobertura.

Não use `// ignore:` em código autoral para esconder uma falha de análise. Se uma exceção for inevitável,
limite-a no `analysis_options.yaml`, explique o motivo e mantenha uma regra estreita.

Para excluir trechos da cobertura, use somente quando o trecho é realmente impossível de executar no teste e
registre a razão:

```dart
// coverage:ignore-line — fallback de plataforma impossível no host do CI
return PlatformDispatcher.instance.locale;

// coverage:ignore-start
// bootstrap gerado pelo plugin, exercitado apenas no device
// coverage:ignore-end
```

`// coverage:ignore-file` é aceitável para um arquivo inteiro gerado ou exclusivamente de bootstrap, nunca
para uma feature só porque ela ainda não tem testes.

## Cobertura com threshold

```bash
flutter test --coverage
```

Gera `coverage/lcov.info`. Para impor um mínimo, duas opções sem dependência exótica:

```bash
# opção A — Very Good CLI
dart pub global activate very_good_cli
very_good test --min-coverage 80

# opção B — lcov puro
lcov --remove coverage/lcov.info \
  '**/*.g.dart' '**/*.freezed.dart' '**/generated/**' \
  -o coverage/lcov_clean.info
genhtml coverage/lcov_clean.info -o coverage/html
lcov --summary coverage/lcov_clean.info
```

Trate 80% como piso administrativo, não como meta. Cobertura mede linhas executadas, não comportamento
verificado — 100% de cobertura com `verify(...).called(1)` em tudo não prova nada. A pergunta que vale é
sempre a do fim de `antipadroes.md`.

Faça o threshold subir junto com o projeto, nunca descer. Se o agente propuser baixar o mínimo para fazer
o CI passar, isso é um sinal de que a suíte nova é fraca.

## Métricas de código

```yaml
# analysis_options.yaml
dart_code_metrics:
  metrics:
    cyclomatic-complexity: 15
    number-of-parameters: 5
    maximum-nesting-level: 4
    source-lines-of-code: 100
  rules:
    - avoid-unused-parameters
    - no-empty-block
    - prefer-conditional-expressions
```

```bash
dart run dart_code_metrics:metrics analyze lib
dart run dependency_validator          # dependência declarada e não usada
```

Complexidade alta num arquivo escrito por agente costuma indicar que ele resolveu o caso com camadas de
`if` em vez de mudar a modelagem — vale pedir refactor antes de testar.

## Mutation testing

É a única técnica que mede a **qualidade** das asserções, não a quantidade de linhas cobertas: ela altera
a implementação de propósito (inverte condição, troca operador, remove chamada) e verifica se algum teste
fica vermelho. Mutante sobrevivente = teste que não protege nada.

Em Dart existe o pacote `mutation_test` no pub.dev. É bem menos maduro que Stryker (JS) ou PIT (Java) e é
lento, então rode pontualmente:

```bash
dart pub global activate mutation_test
mutation_test lib/domain/ --builder=flutter
```

Escopo recomendado: só o núcleo de negócio (cálculos, regras, máquinas de estado), fora do CI de PR —
num job noturno ou manual.

## Teste flaky

Flaky corrói a confiança na suíte mais rápido que teste ausente, porque ensina o time a reexecutar até
passar. Para caçar:

```bash
flutter test --test-randomize-ordering-seed=random   # acoplamento entre testes
for i in {1..10}; do flutter test test/suspeito_test.dart || break; done
```

Causas quase sempre são as mesmas: `DateTime.now()` sem `Clock`, `Random()` sem seed, `Future.delayed`,
estado global entre testes, e dependência de ordem. Todas têm conserto em `padroes-de-teste.md`.

Teste flaky nunca deve ser marcado com `skip` — ou conserta, ou apaga. `skip` acumulado vira suíte morta.

## CI

`assets/ci.yml` traz um workflow de GitHub Actions pronto. Pontos que importam:

- Rodar em todo PR, com o job marcado como obrigatório para merge. Gauntlet que não bloqueia merge é
  decoração.
- Fixar a versão do Flutter (`flutter-version: 'x.y.z'`, sem `channel: master`) — senão a suíte quebra
  sozinha num dia qualquer.
- Cache do pub para o tempo não explodir.
- Golden test em um único sistema operacional.
- Integration test em job separado, não bloqueante no PR se for lento — ou só no merge para `main`.

## Instalando num projeto existente

Projeto legado sem testes trava se você exigir 80% de cara. Sequência que funciona:

1. Ligue `dart format` e o analyzer **sem** as promoções a `error`, e corrija o que aparecer.
2. Ative as promoções uma por vez, começando por `unawaited_futures`.
3. Defina o threshold de cobertura no valor atual do projeto (mesmo que seja 12%) e trave a queda:
   cobertura só pode subir. Isso já impede que código novo entre sem teste.
4. Escreva teste primeiro para o núcleo de negócio e para os bugs que já apareceram em produção — cada
   bug corrigido ganha um teste de regressão antes do fix.
5. Suba o threshold conforme a suíte cresce.

Nunca proponha uma varredura escrevendo teste para o código inteiro de uma vez: gera centenas de testes
decorativos, infla a cobertura e não pega nada.
