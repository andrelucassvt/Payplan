# Exemplo: Navegação (GoRouter)

Cenário: rotas simples, com parâmetros, guard de autenticação, bottom nav e navegação via estado de Cubit.

**Referências**: `navigation.md`, `view-model.md`

---

## Estrutura base

```
lib/config/routes/
├── app_routes.dart    ← constantes de path
└── app_router.dart    ← configuração do GoRouter
```

---

## app_routes.dart

```dart
// lib/config/routes/app_routes.dart
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';

  // Auth
  static const String login = '/login';
  static const String register = '/register';

  // Profile
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // Products
  static const String products = '/products';
  static const String productDetails = '/products/:id';
}
```

---

## app_router.dart — Configuração básica

```dart
// lib/config/routes/app_router.dart
import 'package:base_app/config/routes/app_routes.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeView(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginView(),
    ),

    // Rota com parâmetro de path
    GoRoute(
      path: AppRoutes.productDetails, // '/products/:id'
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProductDetailsView(productId: id);
      },
    ),

    // Rota com subrotas
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileView(),
      routes: [
        GoRoute(
          path: 'edit', // ⚠️ SEM barra inicial em subrotas
          builder: (context, state) => const EditProfileView(),
        ),
      ],
    ),
  ],
);
```

---

## Como navegar na View

```dart
// Push — empilha nova tela (tem botão voltar)
context.push(AppRoutes.home);
context.push('/products/${product.id}');

// Go — substitui a rota atual (sem botão voltar)
context.go(AppRoutes.home);

// Replace — substitui apenas o topo do stack
context.replace(AppRoutes.login);

// Pop — volta para a tela anterior
context.pop();
context.pop('resultado'); // passa valor de retorno

// Aguardar resultado da tela empilhada
final result = await context.push<String>(AppRoutes.editProfile);
if (result != null) { /* usa resultado */ }
```

---

## Padrão 1 — Navegação direta na View (simples)

```dart
ElevatedButton(
  onPressed: () {
    _cubit.selectProduct(product); // lógica no Cubit
    context.push('/products/${product.id}'); // navegação na View
  },
  child: Text(l10n.viewDetailsButton),
)
```

---

## Padrão 2 — Estado de navegação + BlocListener (recomendado para ações async)

```dart
// State
class LoginNavigateToHome extends LoginState {
  const LoginNavigateToHome();

  @override
  String toString() => 'LoginNavigateToHome';
}

// Cubit
result.when(
  ok: (_) => emit(const LoginNavigateToHome()),
  error: (e) => emit(LoginError(LoginErrorKind.invalidCredentials, error: e)),
);

// View
BlocConsumer<LoginCubit, LoginState>(
  listener: (context, state) {
    if (state is LoginNavigateToHome) context.go(AppRoutes.home);
    if (state is LoginError) {
      AppSnackbar.showError(
        context,
        message: switch (state.kind) {
          LoginErrorKind.invalidCredentials => context.l10n.loginInvalidCredentials,
          LoginErrorKind.offline => context.l10n.errorOffline,
          LoginErrorKind.generic => context.l10n.errorGeneric,
        },
      );
    }
  },
  builder: (context, state) { /* ... */ },
)
```

> Estado de navegação é seguro aqui porque a transição é `go` — a `LoginView` é descartada
> e ninguém volta para ela. Com `push`, ver a ressalva em `references/navigation.md`.

---

## Passando objeto complexo via extra

```dart
// Navegação
context.push(AppRoutes.productDetails, extra: product);

// No router
GoRoute(
  path: AppRoutes.productDetails,
  builder: (context, state) {
    final product = state.extra as ProductEntity;
    return ProductDetailsView(product: product);
  },
),
```

---

## Guard de autenticação (redirect)

```dart
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: (context, state) {
    final isLoggedIn = AppInjector.inject<AuthService>().isLoggedIn;
    final isGoingToLogin = state.matchedLocation == AppRoutes.login;
    final isGoingToSplash = state.matchedLocation == AppRoutes.splash;

    // Não logado e tentando acessar tela protegida
    if (!isLoggedIn && !isGoingToLogin && !isGoingToSplash) {
      return AppRoutes.login;
    }

    // Já logado tentando ir para login
    if (isLoggedIn && isGoingToLogin) {
      return AppRoutes.home;
    }

    return null; // sem redirecionamento
  },
  routes: [ /* ... */ ],
);
```

---

## Bottom Navigation com StatefulShellRoute

```dart
final GoRouter appRouter = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainScaffold(
        navigationShell: navigationShell,
      ),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeView())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: AppRoutes.products, builder: (_, _) => const ProductsView())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileView())],
        ),
      ],
    ),
  ],
);

// MainScaffold — preserva a árvore e o scroll de cada aba
class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home),
            label: context.l10n.homeTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list),
            label: context.l10n.productsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person),
            label: context.l10n.profileTab,
          ),
        ],
      ),
    );
  }

}
```

---

## Erros comuns

| Erro | Correto |
|---|---|
| `Navigator.of(context).push(...)` | `context.push(AppRoutes.home)` |
| `path: '/edit'` em subrota | `path: 'edit'` (sem barra) |
| `state.pathParameters['id']` | `state.pathParameters['id']!` |
| Navegação no Cubit com `BuildContext` | Navegação na View ou `BlocListener` |
| Redirect loop | Logar state antes do redirect; verificar inicialização do provider de auth |
