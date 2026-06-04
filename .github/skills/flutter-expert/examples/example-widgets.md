# Exemplo: Extração de Widgets

Cenário: como e onde extrair widgets da View.

**Referências**: `widget.md`, `view.md`

---

## Onde colocar cada widget

```
presentation/profile/
├── widgets/          ← widget reutilizável dentro (ou entre) features
│   ├── profile_card.dart       (card com identidade própria)
│   └── profile_form.dart       (formulário com controllers)
└── content/          ← bloco auxiliar fortemente acoplado a uma única View
    └── profile_empty_section.dart

common/widgets/       ← compartilhado entre features
└── app_button.dart
```

**Regra de decisão rápida:**
- Bloco > 20 linhas ou repetido? → extrair para `widgets/`
- Auxiliar acoplado a uma única View? → mover para `content/`
- Vai ser usado por outra feature? → mover para `common/widgets/`

---

## StatelessWidget — recebe Entity completa

```dart
// lib/presentation/profile/widgets/profile_card.dart
import 'package:base_app/domain/entities/user_entity.dart';
import 'package:base_app/l10n/l10n.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.user, super.key});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(user.email),
            const SizedBox(height: 4),
            Text(l10n.ageLabel(user.age)),
          ],
        ),
      ),
    );
  }
}
```

**Erros comuns:**
```dart
// ❌ Campos individuais como parâmetros
ProfileCard(name: user.name, email: user.email, age: user.age)

// ✅ Entity completa
ProfileCard(user: user)
```

---

## StatefulWidget — tem controllers/animações

```dart
// lib/presentation/profile/widgets/profile_form.dart
import 'package:base_app/domain/entities/user_entity.dart';
import 'package:base_app/l10n/l10n.dart';
import 'package:flutter/material.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({required this.user, required this.onSave, super.key});

  final UserEntity user;
  final void Function(String name, String email) onSave;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(_nameController.text, _emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.nameLabel),
            validator: (v) => v?.isEmpty ?? true ? l10n.nameRequired : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: l10n.emailLabel),
            validator: (v) => v?.isEmpty ?? true ? l10n.emailRequired : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleSave,
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );
  }
}
```

---

## Widget de Lista com ValueKey

```dart
// lib/presentation/products/widgets/product_list_item.dart
import 'package:base_app/domain/entities/product_entity.dart';
import 'package:base_app/l10n/l10n.dart';
import 'package:flutter/material.dart';

class ProductListItem extends StatelessWidget {
  const ProductListItem({
    required this.product,
    required this.onTap,
    super.key, // sempre repasse — permite reconciliação em listas
  });

  final ProductEntity product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(product.imageUrl)),
      title: Text(product.name),
      subtitle: Text(context.l10n.currencyLabel(product.price)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// Uso na View:
ListView.builder(
  itemCount: state.products.length,
  itemBuilder: (context, index) {
    final product = state.products[index];
    return ProductListItem(
      key: ValueKey(product.id), // ✅ ID único em listas dinâmicas
      product: product,
      onTap: () => context.read<ProductsCubit>().select(product),
    );
  },
)
```

---

## Content — bloco acoplado à View, acessa Cubit via context.read

```dart
// lib/presentation/profile/content/profile_save_bar.dart
import 'package:base_app/l10n/l10n.dart';
import 'package:base_app/presentation/profile/view_model/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileSaveBar extends StatelessWidget {
  const ProfileSaveBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        // ✅ context.read: não causa rebuild, só despacha ação
        onPressed: () => context.read<ProfileCubit>().saveProfile(),
        child: Text(context.l10n.saveButton),
      ),
    );
  }
}
```

> `content/` usa `context.read<>()` porque a View envolveu o subtree com `BlocProvider.value`.
> `widgets/` recebe callbacks como parâmetro para manter o widget desacoplado do Cubit.

---

## Exceto quando: Dialog e BottomSheet ficam na View

```dart
// ✅ Funções que abrem Dialog/BottomSheet PODEM ficar na View
void _showConfirmDialog() {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(context.l10n.confirmTitle),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancelButton),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _cubit.deleteItem();
          },
          child: Text(context.l10n.confirmButton),
        ),
      ],
    ),
  );
}
```

---

## Tabela de referência

| Tipo | Permitido na View? |
|---|---|
| `void _showXxxDialog()` | ✅ Sim |
| `void _showXxxBottomSheet()` | ✅ Sim |
| `void _onTapXxx()` (handler puro) | ✅ Sim |
| `Widget _buildXxx()` | ❌ Extrair para `widgets/` ou `content/` |
| `class _XxxContent extends StatelessWidget` | ❌ Extrair para `content/` |

| Local | Acessa Cubit? | Recebe callback? |
|---|---|---|
| `widgets/` (reutilizável) | ❌ Não | ✅ Sim |
| `content/` (específico da View) | ✅ Sim via `context.read` | Opcional |
| `common/widgets/` | ❌ Não | ✅ Sim |
