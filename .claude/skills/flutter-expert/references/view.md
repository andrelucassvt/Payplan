# View — Flutter

## Leitura Rápida

- **Quando criar uma View**: use `StatefulWidget`, obtenha o Cubit via `AppInjector.inject.get<XCubit>()`, use `BlocBuilder` para reagir a estados.
- **Quando carregar dados iniciais**: chame `_cubit.load*()` no `initState()` — use `didChangeDependencies()` apenas se precisar do `context`.
- **Quando navegar entre telas**: SEMPRE use `context.push/go/pop` na View ou em `BlocListener` — nunca passe `BuildContext` ao Cubit.
- **Quando exibir texto ao usuário**: SEMPRE use `context.l10n.<chave>` — nunca string hardcoded.
- **Quando a View for descartada**: feche o Cubit no `dispose()` com `_cubit.close()`.
- **NUNCA crie métodos privados que retornam Widget** (ex: `Widget _buildHeader()`) nem **classes privadas de widget** — nem na View nem em arquivos `content/`/`widgets/`. Invariante universal: extraia para um arquivo próprio com identidade.
- **Exceção**: funções privadas que abrem `showDialog()`, `showModalBottomSheet()` ou similares **podem** permanecer na View.
- **SafeArea**: SEMPRE envolva o conteúdo principal com `SafeArea`.

---

## Princípio Fundamental

**CRIAÇÃO MÍNIMA**: Crie apenas o essencial. Não adicione estruturas (entities, repositories, datasources) até que sejam realmente necessárias.

### Arquivos Essenciais para uma Nova View

Ao criar uma feature chamada `profile`, crie **APENAS**:

```
lib/presentation/profile/
├── view/
│   └── profile_view.dart           # ✅ OBRIGATÓRIO
├── view_model/
│   ├── profile_cubit.dart          # ✅ OBRIGATÓRIO
│   └── profile_state.dart          # ✅ OBRIGATÓRIO
├── (widgets/)                      # ❌ Criar quando extrair widgets da View (mesmo que só usados aqui)
│   └── profile_form.dart
└── (content/)                      # ❌ Criar quando houver blocos de UI auxiliares específicos desta View
    └── profile_content.dart
```

**NÃO CRIAR automaticamente:**
- ❌ widgets/ (criar quando extrair qualquer widget da View — seja reutilizável entre features ou não)
- ❌ content/ (criar quando houver blocos de UI auxiliares específicos de uma única View)
- ❌ utils/ (criar só quando houver formatters/validators específicos)
- ❌ domain/entities/
- ❌ data/models/
- ❌ data/datasources/
- ❌ data/repositories/

---

## Passo a Passo: Criando uma Nova View

### 1 e 2 — Criar State e Cubit

Crie `<feature>_state.dart` (sealed class com Initial, Loading, Loaded, Error) e `<feature>_cubit.dart`.

Ver `view-model.md` para detalhes.

---

### 3 — Criar a View (UI)

**Arquivo**: `lib/presentation/<feature>/view/<feature>_view.dart`

```dart
import 'package:base_app/config/inject/app_injector.dart';
import 'package:base_app/l10n/l10n.dart';
import 'package:base_app/presentation/profile/view_model/profile_cubit.dart';
import 'package:base_app/presentation/profile/view_model/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _cubit = AppInjector.inject.get<ProfileCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Use BlocProvider.value para expor o Cubit ao subtree inteiro.
    // Assim, widgets em `widgets/` e `content/` podem chamar
    // context.read<ProfileCubit>() sem receber callbacks.
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.counterAppBarTitle),
        ),
        body: SafeArea(
          top: false, // AppBar já protege o topo
          child: BlocBuilder<ProfileCubit, ProfileState>(
            // Sem bloc: _cubit — obtido via BlocProvider acima
            builder: (context, state) {
              if (state is ProfileLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProfileError) {
                // ✅ O State carrega a causa; o texto é resolvido aqui
                return Center(
                  child: Text(
                    switch (state.kind) {
                      ProfileErrorKind.offline => l10n.errorOffline,
                      ProfileErrorKind.sessionExpired => l10n.errorSessionExpired,
                      ProfileErrorKind.notFound => l10n.errorProfileNotFound,
                      ProfileErrorKind.generic => l10n.errorGeneric,
                    },
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                );
              }
              if (state is ProfileLoaded) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l10n.profileNameLabel} ${state.name}'),
                      const SizedBox(height: 8),
                      Text('${l10n.profileEmailLabel} ${state.email}'),
                    ],
                  ),
                );
              }
              // ProfileInitial e estados futuros: branch padrão
              return const SizedBox.shrink();
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

**Regras da View:**
- ✅ Sempre `StatefulWidget`
- ✅ Obtém Cubit do `AppInjector` (DI)
- ✅ Usa `BlocProvider.value` para expor o Cubit ao subtree
- ✅ Usa `BlocBuilder` sem `bloc:` quando `BlocProvider.value` está acima
- ✅ Chama `loadData()` no `initState()`
- ✅ Acessa l10n via `context.l10n` e SEMPRE usa para textos visíveis
- ✅ Fecha o Cubit no `dispose()`
- ✅ Trata todos os estados possíveis (Initial, Loading, Loaded, Error)
- ✅ SEMPRE usa `SafeArea`
- ✅ Renderiza estados no `builder` com `if (state is XState)` + early return — **NUNCA** use `switch` expression para o state aqui (dificulta a leitura). O `if (state is X)` promove o tipo, então acesse `state.campo` diretamente. Encerre com um `return` padrão (`const SizedBox.shrink()`) cobrindo `Initial` e estados futuros.
  - ⚠️ Trade-off conhecido: o `switch` sobre sealed class garante exaustividade em tempo de compilação; o `if` + early return não. Por isso o branch `return` final é o default intencional — ao adicionar um novo state, lembre de tratá-lo explicitamente.
  - 📌 Carve-out: a regra geral do projeto prefere `switch`/pattern matching para **enums**. Estados são sealed classes e seguem o idioma de **early return** do projeto — logo, `if` aqui é consistente, não uma exceção.
- ❌ NÃO contém lógica de negócio
- ❌ NÃO faz chamadas HTTP diretamente
- ❌ NÃO cria `Widget _buildXxx()` (invariante universal — vale também em `content/` e `widgets/`)
- ❌ NÃO cria classes privadas de widget (invariante universal — vale também em `content/` e `widgets/`)

---

## BlocProvider.value vs `bloc:` direto

Escolha o padrão com base em quem precisa acessar o Cubit:

| Situação | Padrão recomendado |
|---|---|
| Só o `BlocBuilder` da View precisa do Cubit | `BlocBuilder(bloc: _cubit, ...)` — sem `BlocProvider` |
| Widgets extraídos (`content/`, `widgets/`) chamam o Cubit | `BlocProvider.value(value: _cubit, ...)` + BlocBuilder **sem** `bloc:` |

```dart
// Padrão simples — sem BlocProvider.value
body: BlocBuilder<ProfileCubit, ProfileState>(
  bloc: _cubit, // ← obrigatório quando não há BlocProvider acima
  builder: (context, state) { /* ... */ },
)

// Padrão com acesso no subtree — use BlocProvider.value
return BlocProvider.value(
  value: _cubit,
  child: Scaffold(
    body: BlocBuilder<ProfileCubit, ProfileState>(
      // sem bloc: — BlocBuilder encontra o cubit via context
      builder: (context, state) { /* ... */ },
    ),
  ),
);
```

### Acessando o Cubit em widgets filhos

Quando um widget em `content/` ou `widgets/` precisa chamar um método do Cubit, use `context.read<>()` — nunca passe o Cubit como parâmetro:

```dart
// lib/presentation/profile/content/profile_action_bar.dart
class ProfileActionBar extends StatelessWidget {
  const ProfileActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // ✅ context.read — não rebuild; só chama o método
      onPressed: () => context.read<ProfileCubit>().saveProfile(),
      child: Text(context.l10n.saveButton),
    );
  }
}
```

> `context.read<>()` não causa rebuild — use-o apenas dentro de callbacks. Para **exibir** dados do estado, use `context.watch<>()` ou `BlocBuilder`.

---

## Regra de Layout: SafeArea Obrigatório

| Cenário | SafeArea? |
|---|---|
| Scaffold **com** AppBar | ✅ Envolver o `body` com `top: false` (AppBar protege o topo) |
| Scaffold **sem** AppBar | ✅ Envolver o `body` (protege topo e bottom) |
| Tela fullscreen (splash, onboarding) | ✅ Envolver todo o conteúdo principal |
| Modal/BottomSheet | ✅ Envolver conteúdo com `SafeArea(bottom: true)` |

### ✅ CORRETO — SafeArea com AppBar

```dart
body: SafeArea(
  top: false, // AppBar já protege o topo
  child: BlocBuilder<HomeCubit, HomeState>(
    bloc: _cubit,
    builder: (context, state) { /* ... */ },
  ),
),
```

### ✅ CORRETO — SafeArea sem AppBar

```dart
body: SafeArea(
  child: BlocBuilder<SplashCubit, SplashState>(
    bloc: _cubit,
    builder: (context, state) { /* ... */ },
  ),
),
```

---

## Regra de Composição: Sem Widgets Privados na View

A View deve ser uma orquestradora: instancia Cubit, expõe `BlocProvider`, reage a estado, navega e monta a estrutura principal. Ela não deve virar um arquivo grande cheio de helpers visuais privados.

Métodos `Widget _buildXxx()` não têm `Element` próprio — toda mudança de estado reconstrói o bloco inteiro. Eles também escondem complexidade no mesmo arquivo, deixando a View difícil de revisar. Não resolva uma View grande criando helpers privados; escolha entre inline, `content/` ou `widgets/`.

> Para exemplos detalhados de como extrair widgets corretamente, veja `widget.md`.

### Decisão obrigatória antes de criar UI auxiliar

**Extraia o bloco para arquivo próprio se QUALQUER um for verdadeiro:**
1. O bloco tem **mais de 45 linhas** dentro do `build`.
2. O bloco se **repete em 2+ lugares**.
3. O bloco tem **estado próprio** (controller, timer, animação, `setState`).

Se **nenhum** for verdadeiro → mantenha o bloco **inline no `build()`**, direto na árvore de widgets. **Nunca** transforme um bloco inline em `Widget _buildXxx()` nem em classe privada — se ele incomoda inline, é porque passou na regra de corte e deve virar arquivo.

Ao extrair: `content/` se for específico de uma única View; `widgets/` se tiver identidade própria/reutilização na feature; `common/widgets/` se for usado entre features.

### ✅ Bloco que FICA inline (não passa na regra de corte)

```dart
// ≤45 linhas, usado 1x, sem estado → permanece direto no build()
if (state is ProfileLoaded) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(state.user.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(state.user.email),
        const SizedBox(height: 12),
        Text(l10n.profileBioLabel),
        const SizedBox(height: 4),
        Text(state.user.bio),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => context.read<ProfileCubit>().editProfile(),
          child: Text(l10n.editButton),
        ),
      ],
    ),
  );
}
```

### ❌ Extraído sem necessidade (bloco não passou na regra de corte)

```dart
// ❌ Extrair ~12 linhas para content/ polui a feature sem motivo
if (state is ProfileLoaded) {
  return ProfileInfoContent(user: state.user);
}

// content/profile_info_content.dart  ← arquivo desnecessário
class ProfileInfoContent extends StatelessWidget { ... }
```

### Nome de arquivo da View

Sempre crie Views como `lib/presentation/<feature>/view/<feature>_view.dart`, usando `snake_case` e o nome real da feature.

| Errado | Correto |
|---|---|
| `view-teste.dart` | `profile_view.dart` |
| `nova_view.dart` | `settings_view.dart` |
| `screen1.dart` | `counter_view.dart` |

### ✅ EXCEÇÃO — Funções para Dialog e BottomSheet

```dart
void _showLanguageDialog(String current) {
  showDialog<void>(context: context, builder: (_) => AlertDialog(/*...*/));
}

void _showOptionsBottomSheet() {
  showModalBottomSheet<void>(context: context, builder: (_) => SafeArea(/*...*/));
}
```

### Tabela de referência

| Tipo | Permitido na View? |
|---|---|
| Bloco ≤45 linhas, usado 1x, sem estado | ✅ Inline no build |
| `void _showXxxDialog()` | ✅ Sim |
| `void _showXxxBottomSheet()` | ✅ Sim |
| `void _onTapXxx()` (handler) | ✅ Sim |
| `String _errorText(l10n, kind)` (tradução de causa) | ✅ Sim — retorna dado, não Widget |
| `Widget _buildXxx()` | ❌ Não — extrair para `widgets/` ou `content/` |
| `class _XxxContent extends StatelessWidget` | ❌ Não — extrair para `content/` |

Como os States de erro carregam a **causa** (`XErrorKind`) e não o texto, a View concentra a
tradução em um helper. Ele retorna `String`, então não viola a regra de `Widget _buildXxx()`:

```dart
String _errorText(AppLocalizations l10n, ProfileErrorKind kind) => switch (kind) {
      ProfileErrorKind.offline => l10n.errorOffline,
      ProfileErrorKind.sessionExpired => l10n.errorSessionExpired,
      ProfileErrorKind.notFound => l10n.errorProfileNotFound,
      ProfileErrorKind.generic => l10n.errorGeneric,
    };
```

> As proibições de `Widget _buildXxx()` e classes privadas de widget são **invariantes universais** — aplicam-se também a arquivos `content/` e `widgets/`, não apenas à View.

---

### 4 — Configurar Rota

```dart
// lib/config/routes/app_routes.dart
class AppRoutes {
  static const String profile = '/profile'; // ✅ Adicionar
}

// lib/config/routes/app_router.dart
GoRoute(
  path: AppRoutes.profile,
  builder: (context, state) => const ProfileView(),
),
```

---

### 5 — Registrar Cubit no DI

```dart
// lib/config/inject/app_injector.dart
inject.registerFactory<ProfileCubit>(() => ProfileCubit());
// Com repository:
inject.registerFactory<ProfileCubit>(() => ProfileCubit(inject()));
```

---

## Padrões de UI Comuns

### View com Lista

```dart
builder: (context, state) {
  if (state is ProfileLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  if (state is ProfileError) {
    return Center(child: Text(_errorText(context.l10n, state.kind)));
  }
  if (state is ProfileLoaded) {
    return ListView.builder(
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return ListTile(
          title: Text(item.name),
          onTap: () => context.read<ProfileCubit>().selectItem(item),
        );
      },
    );
  }
  return const SizedBox.shrink();
},
```

### View com BlocConsumer (listener + builder no mesmo bloc) ✅

Quando a mesma View precisa reagir a estados **e** atualizar a UI, use `BlocConsumer`. **Nunca** aninhe `BlocListener` e `BlocBuilder` para o mesmo bloc — isso cria dois listeners desnecessários.

```dart
// ✅ CORRETO — um único widget para listener + builder
BlocConsumer<ProfileCubit, ProfileState>(
  listener: (context, state) {
    if (state is ProfileSaved) {
      AppSnackbar.showSucess(context, message: context.l10n.profileSavedMessage);
      context.pop();
    }
    if (state is ProfileError) {
      AppSnackbar.showError(context, message: _errorText(context.l10n, state.kind));
    }
  },
  builder: (context, state) { /* ... */ },
)
```

```dart
// ❌ ERRADO — BlocListener + BlocBuilder aninhados para o MESMO bloc
BlocListener<ProfileCubit, ProfileState>(
  listener: (context, state) { /* ... */ },
  child: BlocBuilder<ProfileCubit, ProfileState>( // ❌ redundante
    builder: (context, state) { /* ... */ },
  ),
)
```

### View com BlocListener apenas (bloc diferente ou sem UI)

Use `BlocListener` sozinho **somente** quando não há `BlocBuilder` para o mesmo bloc no mesmo nível, ou quando o listener observa um bloc diferente do que constrói a UI.

```dart
// ✅ CORRETO — listener para um bloc, builder para outro
BlocListener<AuthCubit, AuthState>(
  listener: (context, state) {
    if (state is AuthLoggedOut) context.go(AppRoutes.login);
  },
  child: BlocBuilder<ProfileCubit, ProfileState>( // bloc diferente ✅
    builder: (context, state) { /* ... */ },
  ),
)
```

### Navegação após ação assíncrona

```dart
// ✅ Opção A: navegação direta — use sempre que o usuário voltar para esta tela (push)
ElevatedButton(
  onPressed: () => context.push('/details/${item.id}'),
  child: Text(l10n.detailsButton),
)

// ✅ Opção B: estado de navegação — somente quando esta View é descartada (go/replace)
class ProfileNavigateToLogin extends ProfileState {
  const ProfileNavigateToLogin();

  @override
  String toString() => 'ProfileNavigateToLogin';
}

BlocListener<ProfileCubit, ProfileState>(
  listener: (context, state) {
    if (state is ProfileNavigateToLogin) context.go(AppRoutes.login);
  },
  child: /* ... */,
)
```

> **Não use estado de navegação com `push`.** O State é único: emitir `ProfileNavigateToDetails`
> substitui `ProfileLoaded`, o `BlocBuilder` cai no `SizedBox.shrink()` e a tela fica em branco —
> inclusive ao voltar dos detalhes, porque o estado nunca retorna ao de conteúdo.
> Ver `navigation.md` para as três formas de tratar isso.

---

## `widgets/` vs `content/` — qual usar?

A distinção **não é reutilização entre features** — é sobre granularidade e responsabilidade:

| Critério | `widgets/` | `content/` |
|---|---|---|
| Widget com identidade própria (card, form, list item)? | ✅ Sim | ❌ Não |
| Bloco auxiliar fortemente acoplado a uma única View? | ❌ Não | ✅ Sim |
| Usado em várias features? | Pode ser (mova para `common/widgets/`) | ❌ Nunca |
| Exemplo | `ProfileCard`, `HomeItemList`, `ProfileForm` | `RecursosContent`, `HomeEmptySection` |

**Regra prática**: se o bloco seria um `Widget _buildXxx()` na View, extraia para arquivo próprio. Use `content/` quando o bloco for específico de uma única View; use `widgets/` quando houver identidade própria ou intenção real de reutilização dentro da feature.

---

## Checklist de Criação

- [ ] 1. Criar `<feature>_state.dart` e `<feature>_cubit.dart`
- [ ] 2. Criar `<feature>_view.dart` (StatefulWidget, SafeArea, BlocBuilder, todos os estados)
- [ ] 3. Adicionar rota em `app_routes.dart`
- [ ] 4. Adicionar `GoRoute` em `app_router.dart`
- [ ] 5. Registrar Cubit em `app_injector.dart`

**Checklist obrigatório da View antes de finalizar:**
- [ ] O arquivo da View se chama `<feature>_view.dart`
- [ ] Não existe `Widget _buildXxx()` na View
- [ ] Não existe classe privada de widget dentro do arquivo da View
- [ ] Apliquei a regra de corte (45 linhas / repetição / estado) antes de extrair qualquer bloco
- [ ] Blocos que não passaram na regra ficaram inline no build
- [ ] Widgets reutilizáveis foram para `widgets/`
- [ ] Textos visíveis usam `context.l10n`
- [ ] O conteúdo principal está em `SafeArea`

**Criar depois, SE necessário:**
- [ ] Widgets em `widgets/`
- [ ] Auxiliares em `content/`
- [ ] Entity em `domain/entities/`
- [ ] Repository interface, Model, DataSource, RepositoryImpl

---

## Erros Comuns

| Erro | Correto |
|---|---|
| `import '../widgets/profile_card.dart'` | `import 'package:base_app/...'` |
| `inject.registerSingleton<ProfileCubit>()` | `inject.registerFactory<ProfileCubit>()` |
| Não implementar `dispose()` | `_cubit.close(); super.dispose()` |
| Tratar apenas Loading e Loaded | Tratar Initial, Loading, Loaded, Error |
| Strings hardcoded `Text('Salvar')` | `Text(l10n.saveButton)` |
