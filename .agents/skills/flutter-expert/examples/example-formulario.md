# Exemplo: Formulário com Validação e Submit

Cenário: tela de login com email/senha, validação de campos e envio para API.

**Referências**: `view.md`, `view-model.md`, `widget.md`

---

## Estrutura

```
lib/presentation/login/
├── view/login_view.dart
├── view_model/login_cubit.dart
├── view_model/login_state.dart
└── widgets/login_form.dart
```

---

## State

```dart
// lib/presentation/login/view_model/login_state.dart
import 'package:flutter/foundation.dart';

@immutable
sealed class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginSubmitting extends LoginState {
  const LoginSubmitting();
}

class LoginSuccess extends LoginState {
  const LoginSuccess();
}

class LoginError extends LoginState {
  const LoginError(this.message);
  final String message;
}

class LoginFieldError extends LoginState {
  const LoginFieldError({this.emailError, this.passwordError});
  final String? emailError;
  final String? passwordError;
}
```

---

## Cubit

```dart
// lib/presentation/login/view_model/login_cubit.dart
import 'package:base_app/domain/interfaces/auth_repository.dart';
import 'package:base_app/presentation/login/view_model/login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._repository) : super(const LoginInitial());

  final AuthRepository _repository;

  Future<void> submit({
    required String email,
    required String password,
  }) async {
    // Validação local antes de chamar a API
    final emailError = _validateEmail(email);
    final passwordError = _validatePassword(password);

    if (emailError != null || passwordError != null) {
      emit(LoginFieldError(
        emailError: emailError,
        passwordError: passwordError,
      ));
      return;
    }

    emit(const LoginSubmitting());

    final result = await _repository.login(email: email, password: password);

    result.when(
      ok: (_) => emit(const LoginSuccess()),
      error: (e) => emit(LoginError('Email ou senha inválidos')),
    );
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Email obrigatório';
    if (!email.contains('@')) return 'Email inválido';
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Senha obrigatória';
    if (password.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}
```

---

## Widget de Formulário (StatefulWidget com controllers)

```dart
// lib/presentation/login/widgets/login_form.dart
import 'package:base_app/l10n/l10n.dart';
import 'package:base_app/presentation/login/view_model/login_state.dart';
import 'package:flutter/material.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    required this.onSubmit,
    this.fieldError,
    this.isSubmitting = false,
    super.key,
  });

  final void Function(String email, String password) onSubmit;
  final LoginFieldError? fieldError;
  final bool isSubmitting;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    widget.onSubmit(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
              errorText: widget.fieldError?.emailError,
            ),
            onSubmitted: (_) => _handleSubmit(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.passwordLabel,
              errorText: widget.fieldError?.passwordError,
            ),
            onSubmitted: (_) => _handleSubmit(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.isSubmitting ? null : _handleSubmit,
            child: widget.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.loginButton),
          ),
        ],
      ),
    );
  }
}
```

---

## View

```dart
// lib/presentation/login/view/login_view.dart
import 'package:base_app/config/inject/app_injector.dart';
import 'package:base_app/config/routes/app_routes.dart';
import 'package:base_app/l10n/l10n.dart';
import 'package:base_app/presentation/login/view_model/login_cubit.dart';
import 'package:base_app/presentation/login/view_model/login_state.dart';
import 'package:base_app/presentation/login/widgets/login_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _cubit = AppInjector.inject.get<LoginCubit>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.loginTitle)),
        body: SafeArea(
          top: false,
          // BlocConsumer: listener reage a estados + builder constrói UI
          child: BlocConsumer<LoginCubit, LoginState>(
            listener: (context, state) {
              if (state is LoginSuccess) {
                context.go(AppRoutes.home);
              }
              if (state is LoginError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                child: LoginForm(
                  onSubmit: (email, password) =>
                      context.read<LoginCubit>().submit(
                            email: email,
                            password: password,
                          ),
                  fieldError: state is LoginFieldError ? state : null,
                  isSubmitting: state is LoginSubmitting,
                ),
              );
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

---

## DI

```dart
// lib/config/inject/app_injector.dart
inject.registerFactory<LoginCubit>(() => LoginCubit(inject()));
```

---

## Pontos-chave deste padrão

| Aspecto | Decisão |
|---|---|
| Validação | No Cubit — emite `LoginFieldError` com mensagens por campo |
| Controllers | No widget `LoginForm` (StatefulWidget) — não na View |
| Submit loader | `isSubmitting: state is LoginSubmitting` passado como parâmetro |
| Navegação pós-login | `BlocConsumer` listener reage ao `LoginSuccess` |
| Erro de API | `BlocConsumer` listener exibe SnackBar com `LoginError.message` |
| Context no Cubit | ❌ Nunca — Cubit emite estado, View navega |
