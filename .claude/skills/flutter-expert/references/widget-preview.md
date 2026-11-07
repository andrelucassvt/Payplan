# Widget Previewer — Flutter 3.47+

O Widget Previewer permite que o usuário inspecione componentes isolados sem iniciar o app completo. Use-o
para widgets em `presentation/<feature>/widgets/`, `presentation/<feature>/content/` e `common/widgets/`.
Ele complementa, não substitui, widget tests e golden tests.

## Preview mínimo

Crie um arquivo `<widget>_preview.dart` ao lado do widget. A função precisa ser top-level, pública e retornar
`Widget` ou `WidgetBuilder`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:base_app/presentation/products/widgets/product_card.dart';

@Preview(name: 'ProductCard — padrão', group: 'Products')
Widget productCardPreview() => const MaterialApp(
      home: Scaffold(
        body: Center(child: ProductCard(product: ProductEntity.sample)),
      ),
    );

@Preview(
  name: 'ProductCard — escuro',
  group: 'Products',
  brightness: Brightness.dark,
)
Widget productCardDarkPreview() => const MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        body: Center(child: ProductCard(product: ProductEntity.sample)),
      ),
    );
```

Não dependa de `dart:io`, de serviços reais ou de `BuildContext` global. Para assets, use caminhos e
pacotes que o previewer consiga resolver; não leia arquivos do dispositivo. Prefira dados determinísticos
(`ProductEntity.sample`) para que o preview seja reproduzível.

## Estados que merecem preview

Crie uma função separada para cada estado que muda layout ou acessibilidade:

- padrão/carregado;
- vazio;
- erro com ação de retry;
- loading;
- dark mode e texto ampliado quando o componente for sensível a tema ou escala.

Para layouts adaptativos, declare previews compact e expanded com `size`, por exemplo `Size(360, 800)` e
`Size(1200, 800)`. Para `CustomPaint`, use uma dimensão próxima do canvas real e inclua os limites 0%, 50%
e 100% quando houver progresso.

## Workflow

- [ ] O widget extraído tem dados de exemplo determinísticos.
- [ ] Há preview do estado padrão e dos estados que mudam o layout.
- [ ] O preview não faz I/O, não usa `dart:io` e não depende de backend.
- [ ] O widget ainda tem widget test/golden quando o comportamento ou aparência for importante.
- [ ] O usuário executa `flutter widget-preview start` e revisa visualmente os estados.

Se o projeto estiver em versão anterior à estabilidade do Widget Previewer, mantenha o widget test/golden e
registre o preview como opcional até a atualização do Flutter.
