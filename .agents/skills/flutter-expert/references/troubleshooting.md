# Troubleshooting — BLoC + GetIt + GoRouter

Consulte quando um erro em runtime, build ou análise estática aparecer durante a implementação.

| Sintoma | Causa provável | Recovery |
|---|---|---|
| `StateError: Object/factory not found for type XxxCubit` | Cubit não registrado, ou registrado como `LazySingleton` em vez de `Factory` | Adicionar `registerFactory(() => XxxCubit(...))` no AppInjector; conferir se as dependências do construtor também estão registradas |
| `BlocProvider.of<XxxCubit>` lança erro em runtime | Cubit não está acima do widget na árvore | Verificar se a rota provê o Cubit via `BlocProvider`; usar `context.read<XxxCubit>()` somente abaixo do provider |
| `flutter analyze` com erros de import | Import relativo em vez de absoluto | Substituir `import '../...'` por `import 'package:<app>/...'` |
| Chave l10n não encontrada em `context.l10n.<chave>` | Chave ausente em algum `.arb` ou código não regenerado | Adicionar a chave em todos os `.arb` e rodar `flutter gen-l10n` |
| Redirect loop no GoRouter | Condição do guard nunca é satisfeita | Logar o estado antes do `redirect`; verificar se o provider de autenticação já foi inicializado antes da avaliação da rota |
| `Result` nunca entra no caso `ok` | DataSource lança exceção sem `try/catch` no RepositoryImpl | Envolver a chamada em `try/catch` no RepositoryImpl e retornar `Result.error` no `catch` |
| Hot reload não reflete mudanças de estado | Estado persiste no Cubit em memória | Hot restart (`R` no terminal) |
| Entity/State não dispara rebuild quando os dados mudam | `==`/`hashCode` comparam por identidade e o BLoC descarta o novo estado como igual | Implementar `==`/`hashCode` sobre todos os campos relevantes, ou usar uma instância nova em vez de mutar a existente |
| Entity some de um `Set`/`Map` mesmo sendo "igual" | `==` usa `listEquals` mas `hashCode` usa `Object.hash(campo, lista)` — hash por identidade | `Object.hash(campo, Object.hashAll(lista))` — ver `domain.md` |
| Teste falha com `Expected: UserEntity … Actual: UserModel` | `==` da Entity checa `runtimeType`, e o Repository devolve Model | Remover `runtimeType == other.runtimeType` do `==`; `other is UserEntity` basta |
| API responde erro mas a tela mostra conteúdo vazio, sem mensagem | RepositoryImpl não checa status e o `fromJson` preencheu tudo com defaults (`?? ''`) | `ensureSuccess(response)` antes do parsing e defaults só em campos opcionais — ver `data.md` |
| Tela fica em branco depois de navegar e ao voltar | Estado de navegação substituiu o estado de conteúdo, e o `BlocBuilder` caiu no branch padrão | Com `push`, navegue direto na View; estado de navegação só quando a View é descartada — ver `navigation.md` |
| Teste de View lança `StateError: Object/factory not found` | O mock foi passado por `BlocProvider.value`, mas a View resolve o Cubit no `AppInjector` | Registrar o mock no `AppInjector` no `setUp` e `await reset()` no `tearDown` — ver `testing.md` |
| `MissingStubError` no primeiro `pump` de um teste de View | Método chamado no `initState` não foi stubado no `MockCubit` | `when(() => mockCubit.loadX()).thenAnswer((_) async {})` |
| Jank / frames perdidos | `build()` pesado, falta de `const`, rebuilds excessivos | `const` em widgets estáticos; extrair subárvores para `content/` ou `widgets/`; `BlocSelector` para reduzir o escopo do rebuild |
| Cubit emite depois de fechado (`Cannot emit new states after calling close`) | `emit` após `await` em um Cubit já descartado | Checar `isClosed` antes de emitir, ou cancelar a operação em `close()` |
| `An InputDecorator... cannot have an unbounded width` | `TextField` dentro de `Row` sem largura | Envolver o campo em `Expanded`/`Flexible` |
| `Incorrect use of ParentData widget` | `Expanded` fora de `Flex` ou `Positioned` fora de `Stack` | Mover o widget para filho direto do pai que fornece o ParentData correto |
| `RenderBox was not laid out` | Sintoma; a primeira exceção do stack explica a constraint quebrada | Corrigir a primeira mensagem, não o `RenderBox` final |
| `type 'List<dynamic>' is not a subtype of 'List<X>'` | JSON dinâmico não convertido | `(json['items'] as List<dynamic>).cast<Map<String, dynamic>>()` antes do `fromJson` |
| `Null check operator used on a null value` | `!` aplicado em resposta, rota ou estado nullable | Tratar `null` com `?.`/`??` e validar `late`; não espalhar `!` |
| `DioException [connectionTimeout]` ou `connectionError` | Timeout ou rede indisponível | Mapear `DioExceptionType` para `NetworkException` no RepositoryImpl |
| `Target of URI doesn't exist: package:flutter_gen/...` | Import de pacote sintético removido | Usar `synthetic-package: false`, `flutter generate: true` e importar o arquivo gerado em `lib/l10n/` |
| `The getter 'foo' isn't defined` após editar ARB | Geração não executada ou chave ausente | Corrigir todos os ARBs e rodar `flutter gen-l10n` |
| `use_build_context_synchronously` | `context` usado depois de `await` | Retornar cedo se `!context.mounted` antes de navegar ou exibir SnackBar |
| `setState() called after dispose()` | Callback assíncrono terminou depois de desmontar o widget | Verificar `mounted` antes de `setState`, ou cancelar o recurso em `dispose()` |
| `WillPopScope` deprecated ou back gesture quebrado | API antiga de interceptação de back | Migrar para `PopScope(canPop:, onPopInvokedWithResult:)` |
| `withOpacity` deprecated | API de cor descontinuada no SDK atual | Usar `color.withValues(alpha: value)` |

Para travamento de UI durante processamento pesado, use a skill `flutter-isolates`.

---

## Overflow de layout (`RenderFlex overflowed by N pixels`)

Overflow é sintoma de **tamanho disponível**, não de widget errado: o mesmo `build()` que cabe no
simulador do dev estoura em tela estreita, em landscape, com o teclado aberto ou com fonte de
acessibilidade ampliada. Corrigir verificando um único tamanho é o mesmo que não ter corrigido.

| Sintoma | Causa provável | Recovery |
|---|---|---|
| `RenderFlex overflowed ... on the right` | `Row` com `Text` longo — o `Row` não impõe constraint de largura ao filho | `Expanded`/`Flexible` no `Text` + `overflow: TextOverflow.ellipsis`; `Wrap` quando os itens podem quebrar linha |
| `RenderFlex overflowed ... on the bottom` | `Column` mais alta que a tela em aparelho pequeno ou em landscape | `SingleChildScrollView` na `Column`, ou `Expanded` na seção que deve encolher |
| Overflow aparece só ao focar um campo | O teclado reduz a altura disponível e a `Column` não rola | `SingleChildScrollView` + `resizeToAvoidBottomInset: true` (default); `MediaQuery.viewInsetsOf(context).bottom` para padding extra |
| Overflow só com fonte grande | Altura fixa (`SizedBox(height:)`, `Container(height:)`) dimensionada para `textScaler` 1.0 | Trocar altura fixa por `Padding`/`ConstrainedBox(minHeight:)` e deixar o texto definir a altura |
| `Vertical viewport was given unbounded height` | `ListView` dentro de `Column` sem constraint de altura | `Expanded` em volta do `ListView`, ou `shrinkWrap: true` quando a lista é curta |
| Overflow só em tablet/desktop | Largura fixa em pixels ou conteúdo esticado sem largura máxima | `ConstrainedBox(maxWidth:)` no conteúdo de leitura; breakpoints — ver skill `flutter-adaptive-ui` |

**Não resolva com `OverflowBox`, `ClipRect` ou `FittedBox` genérico** — eles apagam a faixa listrada
sem devolver o conteúdo ao usuário: o corte continua, agora silencioso.

### Verificação obrigatória depois de corrigir

Toda correção de overflow é validada em mais de um tamanho:

1. **Estreita** — 320×568 lógicos (iPhone SE) em portrait.
2. **Larga** — largura ≥ 840 lógicos (iPad/desktop).
3. **`textScaler` ampliado** — 1.5× no mínimo; 2.0× em telas com texto denso.
4. **Landscape na tela estreita**, quando a tela permite rotação.

Cubra ao menos os itens 1 e 3 com widget test (`tester.view.physicalSize` e
`MediaQuery.withClampedTextScaling` — ver `testing.md`), porque são os que regridem em silêncio.

Para entender **por que** o filho recebeu aquele tamanho (modelo de constraints do Flutter), leia
`references/layout-constraints.md` da skill `flutter-adaptive-ui`.
