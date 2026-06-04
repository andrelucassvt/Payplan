---
name: custom-paint
description: "Implements Flutter CustomPaint and CustomPainter for drawing 2D graphics on canvas. Use when: the user asks to draw shapes, arcs, paths, gradients, charts, progress indicators, wave animations, custom clipping, or any pixel-level painting on screen. Also covers shouldRepaint optimization, RepaintBoundary, AnimationController integration with CustomPainter, blend modes, canvas transformations, Path operations, image rendering, shadows, SVG path conversion, and canvas hit testing. DO NOT USE FOR: standard widget composition (Row, Stack, Container), image loading/caching, or SVG rendering via flutter_svg. Activate even when the user says 'draw a custom shape', 'create a chart widget', 'animated wave background', 'progress ring', 'gauge meter', 'clip image in a custom shape', or 'pixel-perfect custom design' without explicitly mentioning CustomPaint or CustomPainter."
argument-hint: "Describe what you want to draw (e.g. animated wave, donut chart, custom progress bar, gauge, particle system)"
---

# CustomPaint — Flutter 2D Canvas Drawing

Skill especializada em `CustomPaint` e `CustomPainter` no Flutter, incluindo técnicas avançadas de desenho, performance, animação e integração com a arquitetura do projeto.

> **Referências detalhadas**: APIs de Canvas, Paint, Path, gradientes, sombras, texto, SVG e utilitários de geometria estão em [references/canvas-api.md](./references/canvas-api.md). Padrões prontos (donut, gauge, onda, etc.) em [references/patterns.md](./references/patterns.md).

## Quando Usar

Abrir esta skill quando o usuário pedir:
- Desenhos geométricos customizados (formas, curvas, arcos)
- Gráficos (pizza, barra, linha, donut, gauge, radar/spider)
- Indicadores de progresso com formas não-padrão
- Animações canvas (onda, pulso, partículas, stroke drawing)
- Máscaras, clipping customizado com `ClipPath`
- Gradientes, sombras ou efeitos visuais avançados
- Composição de formas (union, intersect, difference, xor)
- Desenhar imagens no canvas (`ui.Image`)
- Transformações canvas (rotate, scale, translate, skew)
- Animação ao longo de paths (PathMetrics)
- Efeitos de composição (saveLayer + BlendMode)
- Elementos de UI que não podem ser compostos com widgets padrão

## Decisão: CustomPaint vs Alternativas

```
Precisa de pixel control ou formas não-padrão?
  ├── NÃO → use widgets compostos (Stack, Container, DecoratedBox, etc.)
  └── SIM
        ├── É estático e simples? → CustomPaint com CustomPainter
        ├── Precisa de animação? → CustomPaint + AnimationController (ver Passo 3)
        ├── Precisa de interação (toque)? → GestureDetector envolvendo CustomPaint
        ├── É uma máscara/clipping? → ClipPath com CustomClipper
        ├── É um desenho complexo estático? → PictureRecorder para cache (ver Passo 4)
        └── Precisa combinar formas? → Path.combine com PathOperation (ver canvas-api.md §4)
```

## Placement na Arquitetura

| Caso | Onde criar |
|------|-----------|
| Reutilizável entre features | `lib/common/widgets/<nome>_painter.dart` |
| Específico de uma feature | `lib/presentation/<feature>/widgets/<nome>_painter.dart` |
| Auxiliar de uma única View | `lib/presentation/<feature>/content/<nome>_painter.dart` |

Regras gerais:
- O `CustomPainter` NUNCA fica dentro do arquivo da View
- O `CustomPaint` widget também NUNCA é construído via método `Widget _buildXxx()` na View — extraia para uma classe em `widgets/` ou `content/`
- Imports sempre absolutos: `package:base_app/...`

---

## Passo 1 — Criar o CustomPainter

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class MyShapePainter extends CustomPainter {
  const MyShapePainter({
    required this.color,
    required this.progress, // 0.0 a 1.0
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke   // ou PaintingStyle.fill
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round    // arredonda as pontas
      ..strokeJoin = StrokeJoin.round  // arredonda as junções
      ..isAntiAlias = true;

    // Exemplo: arco de progresso circular
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - paint.strokeWidth;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(MyShapePainter oldDelegate) {
    // Só reconstrói se os dados relevantes mudaram
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}
```

**Checklist do CustomPainter:**
- [ ] Classe `final` ou com construtor `const` quando possível
- [ ] Propriedades `final` e passadas pelo construtor
- [ ] `shouldRepaint()` compara APENAS as propriedades que afetam o desenho
- [ ] `shouldRepaint()` NUNCA retorna sempre `true` (causa rebuild desnecessário)
- [ ] Objetos `Paint` e `Path` criados DENTRO de `paint()` (não como campos da classe)
- [ ] Importar `dart:math` quando usar `math.pi`

---

## Passo 2 — Usar CustomPaint no Widget

```dart
// lib/presentation/<feature>/widgets/my_shape_widget.dart
import 'package:flutter/material.dart';
import 'package:base_app/presentation/<feature>/widgets/my_shape_painter.dart';

class MyShapeWidget extends StatelessWidget {
  const MyShapeWidget({
    super.key,
    required this.progress,
    this.color = Colors.blue,
    this.size = 120,
  });

  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(size, size),
        painter: MyShapePainter(color: color, progress: progress),
        // child: Center(child: Text('...')), // opcional: sobreposição de widget
      ),
    );
  }
}
```

**Notas importantes:**
- `size:` define o tamanho quando o widget não tem restrições do pai
- `painter:` desenha ATRÁS dos `child`
- `foregroundPainter:` desenha NA FRENTE dos `child`
- `RepaintBoundary` isola a subárvore de redesenhos do resto da UI

---

> **Nota:** A referência completa de Paint, Canvas, Path, PathOperations, PathMetrics, Images, Shadows, Text, Gradients, SVG e Geometry está em [references/canvas-api.md](./references/canvas-api.md).

---

## Passo 3 — Animação com CustomPainter

Para animar o painter, use `AnimationController` e passe o valor animado como parâmetro:

```dart
// lib/presentation/<feature>/widgets/animated_arc_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:base_app/presentation/<feature>/widgets/my_shape_painter.dart';

class AnimatedArcWidget extends StatefulWidget {
  const AnimatedArcWidget({super.key, required this.color});
  final Color color;

  @override
  State<AnimatedArcWidget> createState() => _AnimatedArcWidgetState();
}

class _AnimatedArcWidgetState extends State<AnimatedArcWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // ou .forward() para uma única vez

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) => CustomPaint(
          size: const Size(120, 120),
          painter: MyShapePainter(
            color: widget.color,
            progress: _progress.value,
          ),
        ),
      ),
    );
  }
}
```

### Animações Staggered (múltiplos controllers)

```dart
class _MultiAnimState extends State<MultiAnimWidget>
    with TickerProviderStateMixin {  // nota: TickerProviderStateMixin (plural)
  late final AnimationController _controller1;
  late final AnimationController _controller2;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller1, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller2, curve: Curves.elasticOut),
    );

    // Stagger: segundo começa quando primeiro termina
    _controller1.forward().then((_) => _controller2.forward());
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }
}
```

### Staggered com um único controller usando Interval

```dart
late final AnimationController _controller = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 2),
);

// Cada animação ocupa um intervalo do controller (0.0–1.0)
final _fadeIn = Tween<double>(begin: 0, end: 1).animate(
  CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
  ),
);
final _slideUp = Tween<double>(begin: 50, end: 0).animate(
  CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
  ),
);
final _scaleUp = Tween<double>(begin: 0.8, end: 1).animate(
  CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
  ),
);
```

**Regras de animação:**
- [ ] Use `AnimatedBuilder` — evita rebuilds desnecessários do widget pai
- [ ] `_controller.dispose()` sempre no `dispose()`
- [ ] `with SingleTickerProviderStateMixin` para um controller; `TickerProviderStateMixin` para múltiplos
- [ ] `shouldRepaint()` no painter deve comparar o valor animado — retorna `true` quando muda
- [ ] Para staggered simples, prefira `Interval` com um único controller

---

## Passo 4 — Performance Avançada

### 4.1 — PictureRecorder (Cache de desenho complexo)

Para desenhos estáticos complexos, grave em um `Picture` e reutilize:

```dart
import 'dart:ui' as ui;

class CachedPainter extends CustomPainter {
  CachedPainter({
    required this.data,
  });

  final List<DataPoint> data;
  ui.Picture? _cachedPicture;
  List<DataPoint>? _cachedData;

  void _rebuildCache(Size size) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Desenho pesado aqui (só acontece quando dados mudam)
    _drawComplexChart(canvas, size, data);

    _cachedPicture = recorder.endRecording();
    _cachedData = List.of(data);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Só recria o cache se os dados mudaram
    if (_cachedPicture == null || _cachedData != data) {
      _rebuildCache(size);
    }
    canvas.drawPicture(_cachedPicture!);
  }

  @override
  bool shouldRepaint(CachedPainter old) => old.data != data;
}
```

### 4.2 — Converter Picture em Image (rasterização)

Para desenhos estáticos que não mudam NUNCA, rasterize para `ui.Image`:

```dart
Future<ui.Image> rasterizePicture(
  ui.Picture picture,
  Size size, {
  double devicePixelRatio = 1.0,
}) async {
  final width = (size.width * devicePixelRatio).ceil();
  final height = (size.height * devicePixelRatio).ceil();
  return picture.toImage(width, height);
}
```

### 4.3 — Checklist de Performance

| Cenário | Recomendação |
|---------|-------------|
| Painter não muda | `shouldRepaint` retorna `false` |
| Painter muda frequentemente (animação) | Envolva com `RepaintBoundary` |
| Múltiplos painters independentes | Um `RepaintBoundary` por painter |
| Desenho estático complexo | Use `PictureRecorder` para cache |
| Desenho que nunca muda após criar | Rasterize para `ui.Image` |
| `saveLayer` usado | Minimize — é CARO para a GPU |
| Muitos pontos (>1000) | Use `drawPoints` ou `drawRawPoints` (Float32List) |
| Texto no canvas | Crie `TextPainter` e chame `.layout()` dentro de `paint()` |
| Listas longas com painter por item | Use `RepaintBoundary` no item do `ListView.builder` |
| Paths complexos que não mudam | Pré-compute e armazene como propriedade do painter |
| Animação suave sem jank | NUNCA aloque listas/maps dentro de `paint()` |

### 4.4 — drawRawPoints para performance máxima

Para milhares de pontos (partículas, scatter plot), use `Float32List`:

```dart
import 'dart:typed_data';

@override
void paint(Canvas canvas, Size size) {
  // Float32List é muito mais eficiente que List<Offset> para muitos pontos
  final points = Float32List(particleCount * 2);
  for (var i = 0; i < particleCount; i++) {
    points[i * 2] = particles[i].x;
    points[i * 2 + 1] = particles[i].y;
  }

  canvas.drawRawPoints(
    PointMode.points,
    points,
    Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round,
  );
}
```

---

## Passo 5 — ClipPath (Máscara e Clipping)

Use `CustomClipper<Path>` quando precisar recortar um widget em uma forma customizada:

```dart
class WaveClipper extends CustomClipper<Path> {
  const WaveClipper({required this.waveHeight});
  final double waveHeight;

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - waveHeight);
    path.quadraticBezierTo(
      size.width / 4, size.height,
      size.width / 2, size.height - waveHeight,
    );
    path.quadraticBezierTo(
      3 * size.width / 4, size.height - 2 * waveHeight,
      size.width, size.height - waveHeight,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) =>
      oldClipper.waveHeight != waveHeight;
}

// Uso:
ClipPath(
  clipper: WaveClipper(waveHeight: 30),
  child: Container(color: Colors.blue, height: 200),
)
```

---

## Passo 6 — Hit Testing (Interação)

Para que o CustomPaint responda a toques numa área customizada:

```dart
class InteractiveShapePainter extends CustomPainter {
  InteractiveShapePainter({
    required this.shapePath,
    required this.color,
  });

  final Path shapePath;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(shapePath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(InteractiveShapePainter old) => old.color != color;

  @override
  bool? hitTest(Offset position) {
    // Retorna true apenas se o toque está DENTRO do path
    return shapePath.contains(position);
  }
}

// Uso com GestureDetector:
GestureDetector(
  onTapDown: (details) {
    final localPosition = details.localPosition;
    // O hitTest do painter filtra automaticamente
  },
  child: CustomPaint(
    size: const Size(200, 200),
    painter: InteractiveShapePainter(
      shapePath: myPath,
      color: Colors.blue,
    ),
  ),
)
```

---

## Passo 7 — Acessibilidade

Sempre envolva `CustomPaint` com `Semantics` quando o conteúdo for significativo:

```dart
Semantics(
  label: context.l10n.progressPercentLabel(progress),
  value: '${(progress * 100).toStringAsFixed(0)}%',
  child: CustomPaint(
    size: const Size(120, 120),
    painter: MyShapePainter(color: color, progress: progress),
  ),
)
```

Para painters complexos com múltiplas áreas semânticas, use `semanticsBuilder`:

```dart
@override
SemanticsBuilderCallback? get semanticsBuilder {
  return (Size size) {
    return [
      CustomPainterSemantics(
        rect: Rect.fromLTWH(0, 0, size.width / 2, size.height),
        properties: const SemanticsProperties(
          label: 'Left section',
          textDirection: TextDirection.ltr,
        ),
      ),
      CustomPainterSemantics(
        rect: Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
        properties: const SemanticsProperties(
          label: 'Right section',
          textDirection: TextDirection.ltr,
        ),
      ),
    ];
  };
}

@override
bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;
```

---

## Checklist Final

Antes de concluir a implementação:

| Item | OK? |
|------|-----|
| `CustomPainter` em arquivo separado (não na View) | [ ] |
| Widget que usa `CustomPaint` em `widgets/` ou `content/` | [ ] |
| `shouldRepaint()` compara propriedades relevantes (não retorna `true` fixo) | [ ] |
| `RepaintBoundary` envolvendo o `CustomPaint` | [ ] |
| Objetos `Paint` e `Path` criados dentro de `paint()` | [ ] |
| `AnimationController` tem `dispose()` | [ ] |
| `AnimatedBuilder` usado (não `setState` com listener) | [ ] |
| `Semantics` envolvendo painters com conteúdo significativo | [ ] |
| `canvas.save()` / `canvas.restore()` para cada transformação | [ ] |
| `saveLayer` usado APENAS quando realmente necessário | [ ] |
| Textos visíveis ao usuário usam `context.l10n` | [ ] |
| Imports absolutos (`package:base_app/...`) | [ ] |
| Para >1000 pontos: usar `drawRawPoints` com `Float32List` | [ ] |
| Desenhos estáticos complexos: considerar `PictureRecorder` | [ ] |
| Curvas suaves: usar `cubicTo` com controle de continuidade | [ ] |

---

## Referências

- [Referência de APIs Canvas/Paint/Path/Gradients/Shadows/Text/SVG](./references/canvas-api.md)
- [Padrões reutilizáveis de CustomPainter](./references/patterns.md)
- [Flutter CustomPainter API](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
- [Flutter Canvas API](https://api.flutter.dev/flutter/dart-ui/Canvas-class.html)
- [Flutter Path API](https://api.flutter.dev/flutter/dart-ui/Path-class.html)

---

**Última atualização**: 11 de abril de 2026
