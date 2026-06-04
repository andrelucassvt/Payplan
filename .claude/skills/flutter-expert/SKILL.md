---
name: flutter-expert
description: >
  Flutter Clean Architecture implementation guide (Presentation → Domain ← Data with BLoC + GetIt + GoRouter).
  Use before implementing any Flutter feature, screen, widget, service, or layer. Provides: decision flow for
  what to create (API vs local vs simple UI), layer-specific references (View, Cubit/State, Domain, Data,
  Service, DI, Navigation, Testing, Apple Guidelines), ready-to-use code examples (simple screen, API feature,
  service, widget, navigation, form), global rules for all layers, development cycle with recovery steps,
  advanced layout/theming guidance, and troubleshooting for common BLoC + GetIt + GoRouter errors.
---

# Flutter Expert

> **Importante**: Os padrões desta skill são baseados em uma **proposta de arquitetura de referência**.
> Cada projeto pode ter sua própria estrutura. Leia `references/architecture.md` ao trabalhar em um projeto desconhecido e adapte-se ao que já existe.

## Arquivos de Referência

Leia o arquivo correspondente à camada antes de gerar código. Não leia todos — apenas o que a tarefa exige.

| Referência | Quando ler |
|---|---|
| `references/architecture.md` | **Sempre que iniciar em um projeto desconhecido** — entender a proposta de arquitetura e como explorar a estrutura real do projeto |
| `references/view.md` | Criar ou modificar Views (tela, StatefulWidget, BlocBuilder, SafeArea, BlocConsumer) |
| `references/view-model.md` | Criar ou modificar Cubits e States (async, Result<T>, debounce, formulário, paginação) |
| `references/widget.md` | Criar ou extrair widgets reutilizáveis (`widgets/`, `content/`, `common/widgets/`) |
| `references/domain.md` | Criar Entities ou Repository Interfaces (`lib/domain/**`) |
| `references/data.md` | Criar Models, DataSources ou RepositoryImpl (`lib/data/**`) |
| `references/service.md` | Criar Services em `common/services/` (flags, contadores, gating, onboarding, premium) |
| `references/di.md` | Registrar dependências no AppInjector (`lib/config/inject/**`) |
| `references/navigation.md` | Adicionar rotas, guards, deep links ou navegar entre telas (`lib/config/routes/**`) |
| `references/apple-guidelines.md` | Submissão na App Store, auditoria de conformidade Apple, rejeição pela Apple, `NSUsageDescription`, ATT, IAP obrigatório, Sign in with Apple, HIG, ATS |
| `references/testing.md` | Escrever testes de Cubit (`blocTest`), RepositoryImpl (fakes), e widgets (`MockCubit`) |

## Exemplos de Código

Use os exemplos como referência rápida de código pronto e correto. Prefira consultar o exemplo do cenário mais próximo ao invés de gerar do zero.

| Exemplo | Cenário |
|---|---|
| `examples/example-tela-simples.md` | Tela sem API — View + Cubit + State + Rota + DI |
| `examples/example-feature-api.md` | Feature completa com API REST — todas as camadas |
| `examples/example-service.md` | Common Services — onboarding, feature gate, premium, review prompt |
| `examples/example-widgets.md` | Extração de widgets — StatelessWidget, StatefulWidget, content vs widgets |
| `examples/example-navegacao.md` | Navegação — push/go/pop, parâmetros, guard, ShellRoute |
| `examples/example-formulario.md` | Formulário com validação de campos e submit assíncrono |

---

## Regras Globais (aplicam-se a TODAS as camadas)

- **Imports**: SEMPRE absolutos — `package:base_app/...` — NUNCA relativos
- **Textos na UI**: SEMPRE `context.l10n.<chave>` — ZERO strings hardcoded visíveis ao usuário
- **SafeArea**: SEMPRE envolva o conteúdo principal da View com `SafeArea`
- **Navegação**: SEMPRE na View ou `BlocListener` — NUNCA passe `BuildContext` ao Cubit
- **Error handling**: SEMPRE `Result<T>` (Ok/Error) no Repository — NUNCA relance exceções
- **DI**: Cubits → `registerFactory`; todo o resto → `registerLazySingleton`
- **Entities**: `@immutable`, `const`, `final`, `copyWith()`, `==`, `hashCode`
- **Composição de View**: a View deve orquestrar estado, navegação e estrutura principal. NUNCA crie `Widget _buildXxx()` nem classes privadas de widget dentro da View.
  - Se o bloco visual tiver até ~20 linhas e continuar legível, escreva diretamente no `build`.
  - Se o bloco ficar grande, repetido, ou dificultar a leitura do `build`, extraia para arquivo próprio.
  - Use `presentation/<feature>/content/` para blocos específicos de uma única View.
  - Use `presentation/<feature>/widgets/` para widgets reutilizáveis dentro da feature.
  - Use `common/widgets/` apenas quando for compartilhado entre features.
  - Dialogs, bottom sheets e handlers privados (`void _showXxx()`, `void _onXxx()`) podem ficar na View.
- **Nome de View**: SEMPRE use `snake_case` com sufixo `_view.dart`, seguindo o nome real da feature. Nunca use hífen (`view-teste.dart`) nem nomes genéricos como `teste`, `nova_view` ou `screen1`.
- **Storage**: NUNCA acesse `SharedPreferences` diretamente no Cubit — use `StorageService`
- **Cubit async**: SEMPRE emita `Loading` antes da operação → chame o repository → use `result.when()`
- **Arquivos `.md`**: NUNCA crie para documentar mudanças de código

---

## Fluxo de Decisão: o que criar em uma nova feature?

```
Feature precisa de API ou banco externo?
  ├─ SIM → criar Data Layer completo:
  │         Entity + Repository Interface   → references/domain.md
  │         Model + DataSource + RepositoryImpl → references/data.md
  │         + registrar no AppInjector      → references/di.md
  │
  └─ NÃO ─ precisa persistir dados localmente?
              ├─ SIM → injetar StorageService no Cubit (sem Data Layer)
              │         → references/view-model.md (Opção A2)
              └─ NÃO → apenas View + Cubit + State + rota + DI
```

| Situação | O que criar | Referência |
|---|---|---|
| Tela simples / UI local | View + Cubit + State | `view.md` + `view-model.md` |
| + rota nova | AppRoutes + GoRoute | `navigation.md` |
| + DI novo Cubit | registerFactory | `di.md` |
| + dados locais | StorageService no Cubit | `view-model.md` (Opção A2) |
| + API externa | Entity + Interface + Model + DataSource + RepositoryImpl | `domain.md` + `data.md` |
| Widget reutilizável na feature | `presentation/<feature>/widgets/` | `widget.md` |
| Widget reutilizável entre features | `common/widgets/` | `widget.md` |
| Auxiliar de UI específico de uma View | `presentation/<feature>/content/` | `widget.md` |
| Flag, contador, gating, onboarding | `common/services/` | `service.md` |

---

## Ciclo de Desenvolvimento

Siga esta ordem ao implementar uma feature. Cada etapa inclui o que fazer se algo falhar.

1. **Estrutura** — Defina o fluxo (Fluxo de Decisão acima), crie os arquivos nos diretórios corretos
   - Se errou a camada: mova o arquivo para o diretório correto antes de continuar; imports absolutos facilitam o refactor
2. **Domain** — Crie Entity + Repository Interface
   - Se `flutter analyze` acusar erro: verifique se faltam `@immutable`, `==`/`hashCode`, `copyWith()` ou se há import relativo
3. **Data** — Crie Model + DataSource + RepositoryImpl
   - Se `Result` nunca entra no caso `ok`: o RepositoryImpl tem `try/catch`? O DataSource está lançando exceção ao invés de retornar?
4. **DI** — Registre no AppInjector
   - Cubits → `registerFactory`; todo o resto → `registerLazySingleton`
   - Se GetIt lança `StateError: Object/factory not found`: o tipo está registrado? As dependências do construtor também estão?
5. **Presentation** — Crie Cubit + State + View + widgets
   - Se `BlocProvider.of` lança erro: o Cubit está acima do widget na árvore? A rota provê o BlocProvider?
   - Se hot reload não reflete mudanças de estado: use hot restart (`R` no terminal)
6. **Rota** — Adicione em AppRoutes + AppRouter
   - Se redirect loop: logue o estado antes do `redirect`; verifique se o provider de autenticação já foi inicializado
7. **L10n** — Adicione as chaves nos arquivos `.arb` e rode `flutter gen-l10n`
   - Se chave não encontrada em `context.l10n.<chave>`: a chave existe em todos os arquivos `.arb`? Rodou `flutter gen-l10n`?

---

## Estrutura de Pastas Obrigatória

```
lib/
├── presentation/
│   └── <feature>/
│       ├── view/<feature>_view.dart
│       ├── view_model/<feature>_cubit.dart
│       ├── view_model/<feature>_state.dart
│       ├── widgets/          # reutilizáveis dentro da feature
│       └── content/          # auxiliares de UI específicos (não reutilizáveis)
│
├── domain/
│   ├── entities/<entity>_entity.dart
│   └── interfaces/<feature>_repository.dart
│
├── data/
│   ├── models/<entity>_model.dart
│   ├── datasources/<feature>_remote_datasource.dart
│   └── repositories/<feature>_repository_impl.dart
│
├── common/
│   ├── widgets/
│   └── services/
│
└── config/
    ├── inject/app_injector.dart
    └── routes/app_router.dart + app_routes.dart
```

**Proibido:**
- Criar widgets fora de `presentation/` (exceto `common/widgets/`)
- Acessar DataSources diretamente do Cubit
- Importar classes de `data/` dentro de `domain/`
- Criar arquivos barrel/export

---

## Layout Avançado

| Widget | Quando usar |
|---|---|
| `Expanded` | Preencher todo o espaço restante no eixo principal |
| `Flexible` | Ocupar no máximo o espaço disponível, mas pode ser menor |
| `Wrap` | Itens que podem quebrar linha quando ultrapassam a largura |
| `LayoutBuilder` | Decisões de layout baseadas no espaço disponível do pai |

- **Stack + Positioned**: ancora widgets nas bordas com coordenadas exatas; use `Align` para alinhamento semântico (`center`, `bottomRight`) sem coordenadas fixas
- **OverlayPortal**: use para dropdowns e tooltips customizados que precisam renderizar acima da árvore de widgets
- **LayoutBuilder**: envolva seções que adaptam layout ao espaço do pai; evite no widget raiz da tela (prefira `MediaQuery`)

---

## Theming Avançado

### ThemeExtension
- Crie `ThemeExtension<T>` com `copyWith` e `lerp` para design tokens customizados (cores, espaçamentos, tipografia)
- Registre em `ThemeData.extensions`
- Acesse via `Theme.of(context).extension<MyColors>()!`

### WidgetStateProperty
- `WidgetStateProperty.resolveWith` para variar propriedades por estado (pressed, disabled, hovered, focused)
- `WidgetStateProperty.all(value)` como atalho quando o valor é o mesmo para todos os estados

### Component Themes
- Customize `appBarTheme`, `elevatedButtonTheme`, `cardTheme`, `inputDecorationTheme` dentro de `ThemeData`
- NUNCA use `.copyWith` inline em cada widget para estilo compartilhado


---

## Troubleshooting

| Sintoma | Causa Provável | Recovery |
|---|---|---|
| `StateError: Object/factory not found for type XxxCubit` | Cubit não registrado ou registrado como `LazySingleton` em vez de `Factory` | Adicionar `registerFactory(() => XxxCubit(...))` no AppInjector; verificar que as dependências do construtor também estão registradas |
| `BlocProvider.of<XxxCubit>` lança erro em runtime | Cubit não está acima do widget na árvore | Verificar se a rota provê o Cubit via `BlocProvider`; usar `context.read<XxxCubit>()` somente abaixo do provider |
| `flutter analyze` com erros de import | Import relativo usado em vez de absoluto | Substituir `import '../...'` por `import 'package:base_app/...'` |
| Chave l10n não encontrada / erro de compilação em `context.l10n.<chave>` | Chave ausente em algum arquivo `.arb` | Adicionar a chave em todos os `.arb` e rodar `flutter gen-l10n` |
| Redirect loop no GoRouter | Condição do guard nunca satisfeita | Logar o estado antes do `redirect`; verificar se o provider de autenticação já foi inicializado antes da avaliação da rota |
| `Result` nunca entra no caso `ok` | DataSource lança exceção sem `try/catch` no RepositoryImpl | Verificar que o RepositoryImpl envolve a chamada em `try/catch` e retorna `Result.error` no `catch` |
| Hot reload não reflete mudanças de estado | Estado persiste no Cubit em memória | Usar hot restart (`R` no terminal) para reiniciar o app completo |
| Jank / frames perdidos | `build()` pesado, falta de `const`, rebuilds excessivos | Adicionar `const` em widgets estáticos; extrair subárvores para `content/` ou `widgets/`; usar `BlocSelector` para reduzir escopo de rebuild |
