---
name: flutter-testing
description: Estratégia e implementação de testes em Flutter/Dart projetada para validar código escrito por agentes de IA sem revisão linha a linha — testes unitários, de widget, golden e integração, mocks com mocktail, análise estática rígida, cobertura, métricas e CI. USE SEMPRE que o usuário pedir para escrever, revisar ou corrigir testes em Flutter/Dart; pedir para "garantir que funciona", "validar a implementação", "criar suíte de testes", "configurar CI do app"; reclamar de teste flaky, teste que não pega bug, ou cobertura baixa; ou quando você mesmo for implementar uma feature Flutter e precisar provar que ela funciona. Use também quando o usuário falar em testabilidade, injeção de dependência para teste, mock, golden test, widget test, integration_test, mutation testing ou análise estática em projeto Flutter — mesmo que ele não use a palavra "teste" explicitamente. NÃO use em mudança que não altera comportamento (padding, cor, string, asset, renomeação, typo), em projeto sem código Dart, nem para responder pergunta conceitual sobre testes que não vai virar código.
metadata:
  version: "1.1.0"
  last_modified: 2026-09-20
  min_flutter: "3.35"
  example_prompt: "Crie testes de widget para uma lista longa com fonte ampliada e cobertura"
---

# Flutter Testing

Testes aqui não servem para "ter cobertura". Servem para substituir a leitura linha a linha do código
implementado por um agente. Se a suíte é fraca, ninguém revisou nada — só deixou de verificar.

Isso muda a prioridade: **um teste que não consegue falhar é pior que teste nenhum**, porque produz
confiança falsa. Todo teste escrito sob esta skill precisa passar num critério simples: *se eu quebrar
a implementação de propósito, esse teste fica vermelho?*

## Fluxo de trabalho

### 1. Escrever o critério de aceite antes do código

Antes de implementar qualquer coisa, escreva o comportamento esperado em linguagem natural, incluindo
os caminhos ruins. Esse texto é a única parte que o humano precisa revisar de verdade.

```gherkin
Cenário: token expirado durante sync
  Dado que o usuário está logado com token expirado
  Quando o app tenta sincronizar
  Então deve tentar refresh uma única vez
  E se o refresh falhar, deslogar e navegar para /login
  E não deve perder os dados locais não sincronizados
```

Mostre os critérios ao usuário e confirme antes de escrever teste ou implementação. Se ele já descreveu
o comportamento na conversa, extraia dali e apenas confirme — não faça o usuário repetir.

### 2. Verificar testabilidade antes de escrever o teste

Código não testável gera teste tautológico. Em feature nova isso é decisão de design: defina as costuras
(interface na frente do I/O, dependência pelo construtor) antes da primeira linha. Em código que já existe,
cheque e corrija antes de testar:

- I/O direto (`http`, `SharedPreferences`, `Firebase*`, `path_provider`, `File`) dentro de widget ou de
  lógica de negócio → extraia para uma interface e injete pelo construtor.
- `DateTime.now()`, `Random()`, `Platform.isX` chamados diretamente → injete `Clock` (pacote `clock`),
  `Random` com seed, ou uma abstração de plataforma. Sem isso o teste vira flaky e o "conserto" natural
  do agente é `Future.delayed`, que só esconde o problema.
- Lógica dentro de `build()` ou de `State` → mova para notifier/bloc/use case, testável em Dart puro.
- Singleton acessado por dentro (`GetIt.I<X>()` no meio do método) → receba por parâmetro.

Se a mudança de arquitetura for grande, avise o usuário e proponha o refactor antes de prosseguir —
não escreva teste ruim para contornar código não testável.

### 3. Escolher a camada certa

| Situação | Camada | Custo |
|---|---|---|
| Regra de negócio, mapper, validação, notifier/bloc | unit em Dart puro | ~70% da suíte |
| Estados de tela (loading/error/empty/success), interação, navegação | `testWidgets` | ~25% |
| Fluxo crítico ponta a ponta (login, checkout, onboarding) | `integration_test` | ~5%, só o caminho do dinheiro |
| Componente de design system, regressão visual | golden | pontual, nunca tela inteira |

Suba de camada só quando a de baixo não consegue provar o comportamento. Widget test é ~20x mais lento
que unit test e falha por motivos que não são o bug.

Receitas de código para cada camada: leia `references/padroes-de-teste.md`.

### 4. Escrever o teste — e vê-lo falhar

Padrões inegociáveis:

- **`mocktail`, não `mockito`.** `mockito` exige codegen (`@GenerateMocks` + `build_runner`), passo que
  agente esquece de rodar e que quebra a compilação do teste. `mocktail` é runtime.
- **Prefira fake a mock para estado.** Um repositório em memória testa comportamento; um mock testa que
  você chamou um método.
- **Assere resultado observável**, não chamada interna. `verify(...).called(1)` pode complementar uma
  asserção, nunca ser a única.
- **Cubra os quatro estados** de qualquer operação assíncrona: sucesso, erro, vazio, carregando.
- **Cubra as bordas que o agente ignora**: lista vazia, `null`, timeout, offline, resposta malformada,
  chamada concorrente, cancelamento.
- **Um `expect` que importa** por teste, com nome que descreve o comportamento — não `'test 1'`.

Escrito o teste, rode antes de existir implementação. Ele precisa falhar, e falhar **pela razão certa**: a
asserção de comportamento — não `MissingStubError`, import quebrado ou `UnimplementedError`. Teste que já
passa contra código que ainda não existe não está olhando para nada.

### 5. Implementar até ficar verde

Só agora a implementação, e a menor que satisfaz os critérios do passo 1 — não a generalização que você
imagina que vai precisar depois.

Enquanto o teste está vermelho, o teste é fixo: quem muda é a implementação. Se no meio da implementação
você concluir que a expectativa estava errada, isso é o caso do passo 8 — pare e fale com o usuário, não
ajuste a asserção em silêncio.

### 6. Provar que o teste consegue falhar

Verde não prova nada sozinho — pode estar verde porque a asserção é fraca. No núcleo de negócio (cálculo,
regra, máquina de estado, mapper), faça a checagem à mão antes de seguir:

1. Inverta uma condição ou troque uma constante na implementação.
2. `flutter test` — o teste tem que ficar **vermelho**.
3. Desfaça a quebra.

Se continuou verde com a implementação quebrada, o teste é decorativo: conserte a asserção agora, não
depois. Para rodar isso em escala existe `mutation_test` — lento, pontual e fora do CI de PR, detalhes em
`references/gauntlet-setup.md`.

### 7. Rodar o gauntlet antes de declarar pronto

Nunca diga que a implementação está pronta sem rodar a verificação completa e mostrar a saída:

```bash
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
```

Antes da análise, ofereça `dart fix --dry-run` para mostrar migrações seguras. Só aplique com
`APPLY_FIXES=1` e revisão do diff: `APPLY_FIXES=1 ./scripts/check.sh --apply-fixes`. Nunca aplique fixes
automaticamente em código gerado sem conferir os arquivos incluídos/excluídos.

Se o projeto ainda não tem esse cerco montado (analysis_options rígido, threshold de cobertura, CI),
ofereça montar — os arquivos prontos estão em `assets/`. Detalhes e métricas avançadas (complexidade
ciclomática, dependência não usada, mutation testing) em `references/gauntlet-setup.md`.

### 8. Quando o teste falhar

A ordem de investigação é sempre: **a implementação está errada** → o critério de aceite estava ambíguo
→ o teste está errado. Nessa ordem.

Isso é a regra mais importante desta skill. Alterar a asserção para casar com o output errado transforma
a suíte em teatro. Se depois de investigar você concluir que o teste é que está errado, **pare e explique
ao usuário** por que a expectativa original era inválida antes de mudar qualquer coisa.

Proibido para fazer a suíte passar: `skip: true`, `// ignore:`, `expect(true, isTrue)`, remover o teste,
afrouxar a asserção, e `flutter test --update-goldens` (regravar golden é aceitar a regressão visual
sem olhar — só o humano decide isso).

### Supressões e código gerado

`// ignore:` não corrige uma implementação e é proibido em código autoral. Se um warning legítimo exigir
exceção, prefira uma configuração estreita no `analysis_options.yaml` e documente o motivo. Arquivos gerados
(`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) podem ser excluídos pelo analyzer, mas não devem receber edição
manual.

## Anti-padrões

Agentes produzem um conjunto previsível de testes inúteis: mock da própria classe sob teste, asserção
só de `findsOneWidget`, `Future.delayed` no lugar de `fake_async`, `pumpAndSettle` em tela com animação
infinita, cobertura inflada com teste de getter. Antes de entregar a suíte, releia
`references/antipadroes.md` e verifique se algum deles entrou.

## O que continua exigindo olho humano

Métrica não pega vulnerabilidade nem dependência maliciosa. Sinalize explicitamente ao usuário — e não
trate como coberto pela suíte — qualquer mudança em:

- `pubspec.yaml`: toda dependência nova, sem exceção
- permissões em `AndroidManifest.xml` / `Info.plist`
- auth, criptografia, storage de token (`flutter_secure_storage`, keychain)
- migrations de banco local (Drift/Isar/sqflite) — irreversível em produção
- endpoints novos: para onde a requisição está apontando

## Arquivos desta skill

- `references/padroes-de-teste.md` — receitas de unit, widget, golden e integration test, com mocktail,
  fake_async, MockClient e testes de notifier/bloc. Leia ao escrever qualquer teste.
- `references/antipadroes.md` — catálogo de testes inúteis com o conserto de cada um. Leia antes de
  entregar a suíte.
- `references/gauntlet-setup.md` — cobertura com threshold, dart_code_metrics, mutation testing,
  detecção de teste flaky. Leia ao montar ou endurecer a verificação de um projeto.
- `assets/analysis_options.yaml` — análise estática rígida, pronta para copiar.
- `assets/check.sh` — o gauntlet num comando.
- `assets/ci.yml` — GitHub Actions rodando o gauntlet em cada PR.
- `assets/regras-agente.md` — bloco para colar no `CLAUDE.md` do projeto, com as proibições que o agente
  precisa carregar em toda sessão.
