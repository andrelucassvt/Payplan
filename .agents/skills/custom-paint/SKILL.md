---
name: custom-paint
description: "Implements Flutter CustomPaint and CustomPainter for drawing 2D graphics on canvas. Use when: the user asks to draw shapes, arcs, paths, gradients, charts, progress indicators, wave animations, custom clipping, or any pixel-level painting on screen. Also covers shouldRepaint optimization, RepaintBoundary, AnimationController integration with CustomPainter, blend modes, canvas transformations, Path operations, image rendering, shadows, SVG path conversion, and canvas hit testing. DO NOT USE FOR: standard widget composition (Row, Stack, Container), image loading/caching, or SVG rendering via flutter_svg. Activate even when the user says 'draw a custom shape', 'create a chart widget', 'animated wave background', 'progress ring', 'gauge meter', 'clip image in a custom shape', or 'pixel-perfect custom design' without explicitly mentioning CustomPaint or CustomPainter."
argument-hint: "Describe what you want to draw (e.g. animated wave, donut chart, custom progress bar, gauge, particle system)"
---

# CustomPaint — Flutter 2D Canvas Drawing

Skill especializada em `CustomPaint` e `CustomPainter` no Flutter, incluindo técnicas avançadas de desenho, performance, animação e integração com a arquitetura do projeto.

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
        ├── Precisa de animação? → CustomPaint + AnimationController (ver Passo 5)
        ├── Precisa de interação (toque)? → GestureDetector envolvendo CustomPaint
        ├── É uma máscara/clipping? → ClipPath com CustomClipper
        ├── É um desenho complexo estático? → PictureRecorder para cache (ver Passo 10)
        └── Precisa combinar formas? → Path.combine com PathOperation (ver Passo 7)
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

## Passo 3 — Referência Completa do Paint

O objeto `Paint` controla como os pixels são desenhados. Domine todas as suas propriedades:

```dart
final paint = Paint()
  // === Cor e Estilo ===
  ..color = Colors.blue                        // cor sólida
  ..style = PaintingStyle.fill                 // fill ou stroke
  ..strokeWidth = 2.0                          // largura do traço (só stroke)
  ..strokeCap = StrokeCap.round                // ponta: butt, round, square
  ..strokeJoin = StrokeJoin.round              // junção: miter, round, bevel
  ..strokeMiterLimit = 4.0                     // limite do miter join
  ..isAntiAlias = true                         // suavização de bordas

  // === Shaders (Gradientes) ===
  ..shader = const LinearGradient(
    colors: [Colors.blue, Colors.purple],
  ).createShader(Rect.fromLTWH(0, 0, w, h))

  // === Filtros ===
  ..maskFilter = const MaskFilter.blur(        // desfoque (sombra soft)
    BlurStyle.normal, 8.0,
  )
  ..colorFilter = const ColorFilter.mode(      // filtro de cor
    Colors.red, BlendMode.multiply,
  )
  ..imageFilter = ImageFilter.blur(            // desfoque de imagem
    sigmaX: 4, sigmaY: 4,
  )

  // === Composição ===
  ..blendMode = BlendMode.srcOver              // modo de composição
  ..invertColors = false;                      // inversão de cores
```

### Modos de BlendMode mais usados

| BlendMode | Efeito |
|-----------|--------|
| `srcOver` | Padrão — desenha sobre o existente |
| `multiply` | Multiplica cores (escurece) |
| `screen` | Clareia a composição |
| `overlay` | Combina multiply e screen |
| `darken` | Mantém o pixel mais escuro |
| `lighten` | Mantém o pixel mais claro |
| `colorDodge` | Clareia iluminando |
| `difference` | Subtrai cores (efeito negativo) |
| `srcIn` | Desenha apenas onde já existe conteúdo (máscara) |
| `dstIn` | Mantém destino apenas onde fonte existe |
| `clear` | Apaga pixels (punch hole) |
| `xor` | Exclui a interseção |

---

## Passo 4 — Referência Completa do Canvas

O Canvas é a superfície de desenho. Aqui estão TODOS os métodos agrupados por categoria:

### 4.1 — Desenho de Formas Básicas

```dart
@override
void paint(Canvas canvas, Size size) {
  final paint = Paint()..color = Colors.blue..style = PaintingStyle.fill;

  // Linha
  canvas.drawLine(
    const Offset(0, 0),     // ponto inicial
    Offset(size.width, 0),  // ponto final
    paint,
  );

  // Retângulo
  canvas.drawRect(
    Rect.fromLTWH(10, 10, 100, 50),
    paint,
  );

  // Retângulo arredondado
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, 100, 50),
      const Radius.circular(12),
    ),
    paint,
  );

  // Duplo retângulo arredondado (anel/moldura)
  canvas.drawDRRect(
    RRect.fromRectAndRadius(outerRect, const Radius.circular(20)),
    RRect.fromRectAndRadius(innerRect, const Radius.circular(12)),
    paint,
  );

  // Círculo
  canvas.drawCircle(
    Offset(size.width / 2, size.height / 2), // centro
    50,                                        // raio
    paint,
  );

  // Oval/Elipse
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 120,
      height: 80,
    ),
    paint,
  );

  // Arco
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: 50), // bounding rect
    -math.pi / 2,           // startAngle (topo)
    math.pi,                // sweepAngle (180°)
    true,                   // useCenter (true = fatia de pizza)
    paint,
  );

  // Path customizado
  final path = Path()
    ..moveTo(0, size.height)
    ..lineTo(size.width / 2, 0)
    ..lineTo(size.width, size.height)
    ..close();
  canvas.drawPath(path, paint);

  // Pontos (para partículas, scatter plots)
  canvas.drawPoints(
    PointMode.points,  // points, lines, polygon
    [Offset(10, 10), Offset(20, 20), Offset(30, 15)],
    paint..strokeWidth = 4..strokeCap = StrokeCap.round,
  );

  // Sombra (baseada em elevação Material)
  canvas.drawShadow(
    path,          // path da forma
    Colors.black,  // cor da sombra
    8.0,           // elevação
    true,          // transparentOccluder
  );

  // Vértices (triângulos — para meshes, gradientes complexos)
  canvas.drawVertices(
    Vertices(
      VertexMode.triangles,
      [Offset(0, 0), Offset(100, 0), Offset(50, 100)],
      colors: [Colors.red, Colors.green, Colors.blue],
    ),
    BlendMode.srcOver,
    paint,
  );
}
```

### 4.2 — Transformações do Canvas

Transformações permitem rotacionar, escalar e transladar o sistema de coordenadas. **SEMPRE** use `save()` e `restore()` para isolar transformações:

```dart
@override
void paint(Canvas canvas, Size size) {
  final paint = Paint()..color = Colors.blue..style = PaintingStyle.fill;

  // === PADRÃO: save → transform → draw → restore ===

  // Translação (mover origem)
  canvas.save();
  canvas.translate(size.width / 2, size.height / 2); // mover origem ao centro
  canvas.drawRect(
    Rect.fromCenter(center: Offset.zero, width: 50, height: 50),
    paint,
  );
  canvas.restore();

  // Rotação em torno de um ponto
  canvas.save();
  canvas.translate(size.width / 2, size.height / 2); // mover ao ponto de rotação
  canvas.rotate(math.pi / 4);                         // rotacionar 45°
  canvas.translate(-25, -25);                          // offset para centralizar
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 50, 50),
    paint,
  );
  canvas.restore();

  // Escala
  canvas.save();
  canvas.translate(size.width / 2, size.height / 2);
  canvas.scale(2.0, 1.5);    // scaleX, scaleY
  canvas.drawCircle(Offset.zero, 20, paint);
  canvas.restore();

  // Skew (distorção)
  canvas.save();
  canvas.skew(0.3, 0.0);     // skewX, skewY (em radianos)
  canvas.drawRect(
    const Rect.fromLTWH(50, 50, 80, 60),
    paint,
  );
  canvas.restore();

  // Transformação com Matrix4 (controle total)
  canvas.save();
  final matrix = Float64List.fromList([
    1, 0, 0, 0,   // coluna 1
    0, 1, 0, 0,   // coluna 2
    0, 0, 1, 0,   // coluna 3
    tx, ty, 0, 1,  // coluna 4 (translação)
  ]);
  canvas.transform(matrix);
  canvas.drawPath(path, paint);
  canvas.restore();
}
```

**Regra de ouro:** Para rotacionar/escalar em torno de um ponto específico:
1. `canvas.save()`
2. `canvas.translate(pontoX, pontoY)` — move a origem
3. `canvas.rotate(angulo)` ou `canvas.scale(sx, sy)`
4. `canvas.translate(-pontoX, -pontoY)` — move de volta (se necessário)
5. Desenha
6. `canvas.restore()`

### 4.3 — Clipping no Canvas

```dart
// Clip retangular
canvas.save();
canvas.clipRect(
  Rect.fromLTWH(20, 20, 100, 100),
  clipOp: ClipOp.intersect,  // intersect (padrão) ou difference
);
canvas.drawCircle(center, 80, paint); // só aparece dentro do rect
canvas.restore();

// Clip com retângulo arredondado
canvas.save();
canvas.clipRRect(
  RRect.fromRectAndRadius(rect, const Radius.circular(20)),
);
canvas.drawImage(image, Offset.zero, paint);
canvas.restore();

// Clip com path customizado
canvas.save();
canvas.clipPath(starPath);
canvas.drawRect(fullRect, gradientPaint); // gradiente dentro da estrela
canvas.restore();
```

### 4.4 — saveLayer (Composição Avançada)

`saveLayer` cria uma camada off-screen onde você pode aplicar efeitos de composição:

```dart
// Exemplo: grupo semi-transparente sem sobreposição dupla
canvas.saveLayer(
  Rect.fromLTWH(0, 0, size.width, size.height),
  Paint()..color = Colors.white.withOpacity(0.5),
);
// Tudo desenhado aqui será um grupo único com 50% opacidade
canvas.drawCircle(Offset(80, 80), 40, redPaint);
canvas.drawCircle(Offset(120, 80), 40, bluePaint);
canvas.restore(); // aplica a opacidade do grupo

// Exemplo: efeito de máscara (punch hole)
canvas.saveLayer(bounds, Paint());
canvas.drawRect(bounds, backgroundPaint);  // desenha o fundo
canvas.drawCircle(
  center, 50,
  Paint()..blendMode = BlendMode.clear,    // "apaga" o círculo
);
canvas.restore();

// Exemplo: blend mode customizado
canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.multiply);
canvas.drawImage(image1, Offset.zero, Paint());
canvas.drawImage(image2, Offset.zero, Paint());
canvas.restore(); // images são multiplicadas
```

**⚠️ CUIDADO:** `saveLayer` é CARO — a GPU precisa trocar de render target. Use apenas quando:
- Precisa aplicar opacidade a um grupo de elementos
- Precisa de BlendMode entre elementos do grupo
- Precisa de efeito de máscara (punch hole, cutout)
- NÃO use para simples save/restore de transformações (use `canvas.save()` normal)

---

## Passo 5 — Animação com CustomPainter

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

## Passo 6 — Referência Completa de Path

O `Path` é a ferramenta mais poderosa para desenhos detalhados. Domine TODOS os seus métodos:

### 6.1 — Métodos de Construção

```dart
final path = Path();

// === Movimentação ===
path.moveTo(x, y);                 // mover cursor sem desenhar
path.relativeMoveTo(dx, dy);       // relativo à posição atual

// === Linhas ===
path.lineTo(x, y);                 // linha reta até (x, y)
path.relativeLineTo(dx, dy);       // linha relativa

// === Curvas Quadráticas (1 ponto de controle) ===
path.quadraticBezierTo(
  cpX, cpY,   // ponto de controle
  endX, endY, // ponto final
);
path.relativeQuadraticBezierTo(cpDx, cpDy, endDx, endDy);

// === Curvas Cúbicas (2 pontos de controle — mais suaves) ===
path.cubicTo(
  cp1X, cp1Y,   // primeiro ponto de controle
  cp2X, cp2Y,   // segundo ponto de controle
  endX, endY,   // ponto final
);
path.relativeCubicTo(cp1Dx, cp1Dy, cp2Dx, cp2Dy, endDx, endDy);

// === Curvas Cônicas (peso controla curvatura) ===
path.conicTo(
  cpX, cpY,    // ponto de controle
  endX, endY,  // ponto final
  weight,      // peso: <1 = elíptico, 1 = quadrático, >1 = hiperbólico
);
path.relativeConicTo(cpDx, cpDy, endDx, endDy, weight);

// === Arcos ===
path.arcTo(
  Rect.fromCircle(center: center, radius: r), // oval inscrito
  startAngle,    // em radianos
  sweepAngle,    // extensão em radianos
  forceMoveTo,   // true = não conecta ao ponto anterior
);
path.arcToPoint(
  Offset(endX, endY),           // ponto final
  radius: const Radius.circular(50), // raio do arco
  rotation: 0,                  // rotação do arco (graus)
  largeArc: false,              // arco grande ou pequeno
  clockwise: true,              // sentido horário
);
path.relativeArcToPoint(offset, radius: r);

// === Fechar ===
path.close(); // liga o ponto atual ao início do contorno

// === Formas Completas ===
path.addRect(Rect.fromLTWH(0, 0, 100, 50));
path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(8)));
path.addOval(Rect.fromCenter(center: c, width: 80, height: 60));
path.addArc(rect, startAngle, sweepAngle);
path.addPolygon(
  [Offset(0, 50), Offset(50, 0), Offset(100, 50)], // pontos
  true,  // close
);
path.addPath(otherPath, Offset(dx, dy)); // adiciona outro path com offset

// === Direção ===
path.fillType = PathFillType.evenOdd; // ou nonZero (padrão)
```

### 6.2 — Curvas Bézier: Guia Visual

```
Quadrática (1 controle):        Cúbica (2 controles):
  cp                              cp1         cp2
   *                               *           *
  / \                             /             \
 /   \                           /               \
start  end                    start              end

Quadrática é mais rápida, cúbica é mais flexível.
Use cúbica para curvas em S, ondas suaves, e formas orgânicas.
```

### 6.3 — Conectar Curvas Suavemente (Continuidade G1/C1)

Para curvas suaves contínuas, o ponto de controle da próxima curva deve ser o reflexo do último ponto de controle da curva anterior em relação ao ponto de junção:

```dart
// Curva suave contínua (smooth spline)
Path smoothCurve(List<Offset> points) {
  if (points.length < 2) return Path()..moveTo(points[0].dx, points[0].dy);

  final path = Path()..moveTo(points[0].dx, points[0].dy);

  for (var i = 0; i < points.length - 1; i++) {
    final p0 = i > 0 ? points[i - 1] : points[i];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i + 2 < points.length ? points[i + 2] : p2;

    // Catmull-Rom → Cubic Bezier
    final cp1 = Offset(
      p1.dx + (p2.dx - p0.dx) / 6,
      p1.dy + (p2.dy - p0.dy) / 6,
    );
    final cp2 = Offset(
      p2.dx - (p3.dx - p1.dx) / 6,
      p2.dy - (p3.dy - p1.dy) / 6,
    );

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
  }

  return path;
}
```

---

## Passo 7 — Path Operations (Combinar Formas)

Combine dois paths usando operações booleanas:

```dart
// PathOperation disponíveis:
// - union        → soma das formas
// - intersect    → apenas a interseção
// - difference   → path1 menos path2
// - reverseDifference → path2 menos path1
// - xor          → tudo exceto a interseção

final circle = Path()
  ..addOval(Rect.fromCircle(center: Offset(60, 60), radius: 50));
final square = Path()
  ..addRect(Rect.fromLTWH(40, 40, 80, 80));

// União: forma combinada
final unionPath = Path.combine(PathOperation.union, circle, square);
canvas.drawPath(unionPath, fillPaint);

// Diferença: círculo com buraco quadrado
final differencePath = Path.combine(
  PathOperation.difference,
  circle,
  square,
);
canvas.drawPath(differencePath, fillPaint);

// Interseção: apenas onde ambos se sobrepõem
final intersectPath = Path.combine(
  PathOperation.intersect,
  circle,
  square,
);
canvas.drawPath(intersectPath, fillPaint);
```

### Exemplo prático: Ícone com recorte

```dart
// Criar um coração com um "check" recortado
final heartPath = _createHeartPath(size);
final checkPath = _createCheckPath(size);
final result = Path.combine(PathOperation.difference, heartPath, checkPath);
canvas.drawPath(result, paint);
```

---

## Passo 8 — PathMetrics (Medir e Animar ao longo de Paths)

`PathMetrics` permite medir um path, encontrar posições/tangentes ao longo dele, e extrair sub-paths:

```dart
// Animação de "stroke drawing" (desenho progressivo)
class StrokeAnimationPainter extends CustomPainter {
  const StrokeAnimationPainter({
    required this.path,
    required this.progress,
    required this.color,
    this.strokeWidth = 3,
  });

  final Path path;
  final double progress; // 0.0 a 1.0
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Extrair apenas a porção do path correspondente ao progresso
    for (final metric in path.computeMetrics()) {
      final extractLength = metric.length * progress.clamp(0.0, 1.0);
      final extractedPath = metric.extractPath(0, extractLength);
      canvas.drawPath(extractedPath, paint);
    }
  }

  @override
  bool shouldRepaint(StrokeAnimationPainter old) =>
      old.progress != progress || old.color != color;
}

// Obter posição e tangente num ponto do path
final metrics = path.computeMetrics().first;
final tangent = metrics.getTangentForOffset(metrics.length * 0.5);
if (tangent != null) {
  final position = tangent.position;  // Offset no meio do path
  final angle = tangent.angle;        // ângulo da tangente (radianos)

  // Desenhar um indicador que segue o path
  canvas.save();
  canvas.translate(position.dx, position.dy);
  canvas.rotate(angle);
  canvas.drawPath(arrowPath, paint);
  canvas.restore();
}
```

### Exemplo: Mover um objeto ao longo de um path

```dart
class PathFollowerPainter extends CustomPainter {
  const PathFollowerPainter({
    required this.trackPath,
    required this.progress,
    required this.dotRadius,
    required this.trackColor,
    required this.dotColor,
  });

  final Path trackPath;
  final double progress;
  final double dotRadius;
  final Color trackColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Desenha o trilho
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Posiciona o ponto no path
    final metric = trackPath.computeMetrics().first;
    final tangent = metric.getTangentForOffset(
      metric.length * progress.clamp(0.0, 1.0),
    );

    if (tangent != null) {
      canvas.drawCircle(
        tangent.position,
        dotRadius,
        Paint()..color = dotColor,
      );
    }
  }

  @override
  bool shouldRepaint(PathFollowerPainter old) => old.progress != progress;
}
```

---

## Passo 9 — Desenhar Imagens no Canvas

Para desenhar `ui.Image` no canvas, primeiro carregue a imagem de forma assíncrona:

```dart
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

// Carregar imagem de asset
Future<ui.Image> loadImageFromAsset(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}

// Carregar imagem de Uint8List (ex: rede)
Future<ui.Image> loadImageFromBytes(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}
```

### Usar no Painter

```dart
class ImagePainter extends CustomPainter {
  const ImagePainter({required this.image});
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    // Desenhar imagem inteira numa posição
    canvas.drawImage(image, Offset.zero, Paint());

    // Desenhar parte da imagem (sprite sheet)
    final src = Rect.fromLTWH(0, 0, 64, 64);  // região da imagem
    final dst = Rect.fromLTWH(10, 10, 128, 128); // onde desenhar
    canvas.drawImageRect(image, src, dst, Paint());

    // Imagem com filtro
    canvas.drawImageRect(
      image, src, dst,
      Paint()
        ..colorFilter = const ColorFilter.mode(
          Colors.blue, BlendMode.colorBurn,
        )
        ..filterQuality = FilterQuality.high,
    );

    // Imagem com clip circular
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: 50)),
    );
    canvas.drawImageRect(image, src, dst, Paint());
    canvas.restore();
  }

  @override
  bool shouldRepaint(ImagePainter old) => old.image != image;
}
```

### Widget com carregamento de imagem

```dart
class ImageCanvasWidget extends StatefulWidget {
  const ImageCanvasWidget({super.key, required this.assetPath});
  final String assetPath;

  @override
  State<ImageCanvasWidget> createState() => _ImageCanvasWidgetState();
}

class _ImageCanvasWidgetState extends State<ImageCanvasWidget> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final image = await loadImageFromAsset(widget.assetPath);
    if (mounted) setState(() => _image = image);
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return const SizedBox.shrink();
    }
    return RepaintBoundary(
      child: CustomPaint(
        size: const Size(200, 200),
        painter: ImagePainter(image: _image!),
      ),
    );
  }
}
```

---

## Passo 10 — Performance Avançada

### 10.1 — PictureRecorder (Cache de desenho complexo)

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

### 10.2 — Converter Picture em Image (rasterização)

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

### 10.3 — Checklist de Performance

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

### 10.4 — drawRawPoints para performance máxima

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

## Passo 11 — Sombras Detalhadas

Duas abordagens para sombras no canvas:

### 11.1 — drawShadow (sombra Material)

```dart
// Sombra baseada em elevação — rápida, mas limitada
canvas.drawShadow(
  path,           // Path da forma
  Colors.black,   // Cor da sombra
  8.0,            // Elevação (controla tamanho/blur)
  true,           // transparentOccluder (true se a forma não é opaca)
);
// Depois desenhe a forma por cima
canvas.drawPath(path, fillPaint);
```

### 11.2 — MaskFilter.blur (sombra customizada)

```dart
// Sombra com controle total de offset, cor, blur e opacidade
void drawCustomShadow(
  Canvas canvas,
  Path path, {
  Color color = Colors.black26,
  double blurSigma = 8,
  Offset offset = const Offset(4, 4),
}) {
  final shadowPaint = Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

  // Desenha a sombra com offset
  canvas.save();
  canvas.translate(offset.dx, offset.dy);
  canvas.drawPath(path, shadowPaint);
  canvas.restore();

  // Depois desenhe a forma real por cima (sem offset)
}
```

### 11.3 — Múltiplas sombras (efeito neumórfico)

```dart
void drawNeumorphicShape(Canvas canvas, Rect rect) {
  final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
  final path = Path()..addRRect(rrect);

  // Sombra escura (canto inferior direito)
  drawCustomShadow(
    canvas, path,
    color: Colors.black.withOpacity(0.2),
    blurSigma: 10,
    offset: const Offset(6, 6),
  );

  // Sombra clara (canto superior esquerdo)
  drawCustomShadow(
    canvas, path,
    color: Colors.white.withOpacity(0.7),
    blurSigma: 10,
    offset: const Offset(-6, -6),
  );

  // Forma principal
  canvas.drawRRect(
    rrect,
    Paint()..color = const Color(0xFFE0E0E0),
  );
}
```

---

## Passo 12 — Textos no Canvas

```dart
void _drawText(
  Canvas canvas,
  String text, {
  required Offset position,
  TextStyle style = const TextStyle(color: Colors.white, fontSize: 16),
  double maxWidth = double.infinity,
  TextAlign textAlign = TextAlign.left,
}) {
  final textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: textAlign,
  )..layout(maxWidth: maxWidth);

  textPainter.paint(canvas, position);
}

// Centralizar texto
void _drawCenteredText(
  Canvas canvas,
  Size size,
  String text, {
  TextStyle style = const TextStyle(color: Colors.black, fontSize: 14),
}) {
  final textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: size.width);

  textPainter.paint(
    canvas,
    Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    ),
  );
}

// Texto rotacionado
void _drawRotatedText(
  Canvas canvas,
  String text,
  Offset position,
  double angle,
) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  canvas.save();
  canvas.translate(position.dx, position.dy);
  canvas.rotate(angle);
  textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
  canvas.restore();
}
```

---

## Passo 13 — Gradientes Avançados

```dart
// Linear
final linearPaint = Paint()
  ..shader = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.blue, Colors.purple, Colors.pink],
    stops: [0.0, 0.5, 1.0],
  ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

// Radial
final radialPaint = Paint()
  ..shader = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [Colors.yellow, Colors.orange, Colors.red],
    stops: const [0.0, 0.5, 1.0],
  ).createShader(Rect.fromCircle(center: center, radius: radius));

// Sweep (cônico)
final sweepPaint = Paint()
  ..shader = SweepGradient(
    center: Alignment.center,
    startAngle: 0,
    endAngle: 2 * math.pi,
    colors: [Colors.red, Colors.blue, Colors.green, Colors.red],
    stops: const [0.0, 0.33, 0.66, 1.0],
    transform: GradientRotation(-math.pi / 2), // rotacionar o gradiente
  ).createShader(Rect.fromCircle(center: center, radius: radius));

// Gradiente no stroke (contorno)
final strokeGradientPaint = Paint()
  ..shader = const LinearGradient(
    colors: [Colors.cyan, Colors.purple],
  ).createShader(rect)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 4
  ..strokeCap = StrokeCap.round;
canvas.drawPath(path, strokeGradientPaint);

// Gradiente apenas dentro de um path (clip)
canvas.save();
canvas.clipPath(starPath);
canvas.drawPaint(gradientPaint); // preenche toda a área clipada
canvas.restore();
```

---

## Passo 14 — SVG Path para Flutter Path

Converta comandos SVG para métodos Flutter equivalentes:

| SVG Comando | Flutter Método | Descrição |
|-------------|---------------|-----------|
| `M x,y` | `path.moveTo(x, y)` | Move cursor |
| `m dx,dy` | `path.relativeMoveTo(dx, dy)` | Move relativo |
| `L x,y` | `path.lineTo(x, y)` | Linha reta |
| `l dx,dy` | `path.relativeLineTo(dx, dy)` | Linha relativa |
| `H x` | `path.lineTo(x, currentY)` | Linha horizontal |
| `V y` | `path.lineTo(currentX, y)` | Linha vertical |
| `C x1,y1 x2,y2 x,y` | `path.cubicTo(x1,y1,x2,y2,x,y)` | Curva cúbica |
| `c dx1,dy1 dx2,dy2 dx,dy` | `path.relativeCubicTo(...)` | Cúbica relativa |
| `Q x1,y1 x,y` | `path.quadraticBezierTo(x1,y1,x,y)` | Curva quadrática |
| `q dx1,dy1 dx,dy` | `path.relativeQuadraticBezierTo(...)` | Quadrática relativa |
| `A rx,ry rot large,sweep x,y` | `path.arcToPoint(...)` | Arco elíptico |
| `Z` | `path.close()` | Fechar path |

### Parser simples de SVG Path

```dart
/// Converte string SVG path "M10,20 L30,40 ..." em Path do Flutter
/// Para formas complexas, use o pacote `path_parsing` ou converta manualmente.
Path parseSvgPathData(String svgPath) {
  final path = Path();
  // Regex para separar comandos SVG
  final commands = RegExp(r'([MmLlHhVvCcSsQqTtAaZz])([^MmLlHhVvCcSsQqTtAaZz]*)')
      .allMatches(svgPath);

  double cx = 0, cy = 0; // posição atual

  for (final match in commands) {
    final cmd = match.group(1)!;
    final params = match.group(2)!
        .trim()
        .split(RegExp(r'[\s,]+'))
        .where((s) => s.isNotEmpty)
        .map(double.parse)
        .toList();

    switch (cmd) {
      case 'M':
        path.moveTo(params[0], params[1]);
        cx = params[0]; cy = params[1];
      case 'm':
        path.relativeMoveTo(params[0], params[1]);
        cx += params[0]; cy += params[1];
      case 'L':
        path.lineTo(params[0], params[1]);
        cx = params[0]; cy = params[1];
      case 'l':
        path.relativeLineTo(params[0], params[1]);
        cx += params[0]; cy += params[1];
      case 'H':
        path.lineTo(params[0], cy);
        cx = params[0];
      case 'h':
        path.relativeLineTo(params[0], 0);
        cx += params[0];
      case 'V':
        path.lineTo(cx, params[0]);
        cy = params[0];
      case 'v':
        path.relativeLineTo(0, params[0]);
        cy += params[0];
      case 'C':
        path.cubicTo(
          params[0], params[1], params[2],
          params[3], params[4], params[5],
        );
        cx = params[4]; cy = params[5];
      case 'c':
        path.relativeCubicTo(
          params[0], params[1], params[2],
          params[3], params[4], params[5],
        );
        cx += params[4]; cy += params[5];
      case 'Q':
        path.quadraticBezierTo(
          params[0], params[1], params[2], params[3],
        );
        cx = params[2]; cy = params[3];
      case 'q':
        path.relativeQuadraticBezierTo(
          params[0], params[1], params[2], params[3],
        );
        cx += params[2]; cy += params[3];
      case 'Z' || 'z':
        path.close();
    }
  }
  return path;
}
```

**Dica:** Para SVGs complexos exportados de Figma/Illustrator, use o pacote `path_parsing` no pub.dev ou converta manualmente comando por comando.

---

## Passo 15 — ClipPath (Máscara e Clipping)

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

## Passo 16 — Hit Testing (Interação)

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

## Passo 17 — Acessibilidade

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

## Passo 18 — Utilitários de Geometria

Funções auxiliares que aparecem frequentemente em painters detalhados:

```dart
import 'dart:math' as math;

/// Converte graus para radianos
double degToRad(double deg) => deg * math.pi / 180;

/// Converte radianos para graus
double radToDeg(double rad) => rad * 180 / math.pi;

/// Ponto na circunferência dado ângulo e raio
Offset pointOnCircle(Offset center, double radius, double angleRad) {
  return Offset(
    center.dx + radius * math.cos(angleRad),
    center.dy + radius * math.sin(angleRad),
  );
}

/// Distância entre dois pontos
double distance(Offset a, Offset b) => (a - b).distance;

/// Lerp entre dois Offsets (interpolação linear)
Offset lerpOffset(Offset a, Offset b, double t) {
  return Offset(
    a.dx + (b.dx - a.dx) * t,
    a.dy + (b.dy - a.dy) * t,
  );
}

/// Normalizar valor de um range para 0.0–1.0
double normalize(double value, double min, double max) {
  return ((value - min) / (max - min)).clamp(0.0, 1.0);
}

/// Mapear valor de um range para outro
double mapRange(
  double value,
  double inMin, double inMax,
  double outMin, double outMax,
) {
  return outMin + (outMax - outMin) * normalize(value, inMin, inMax);
}

/// Criar path de estrela
Path createStarPath(Offset center, int points, double outerR, double innerR) {
  final path = Path();
  final step = math.pi / points;
  for (var i = 0; i < points * 2; i++) {
    final r = i.isEven ? outerR : innerR;
    final angle = i * step - math.pi / 2;
    final point = pointOnCircle(center, r, angle);
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  return path;
}

/// Criar path de polígono regular
Path createPolygonPath(Offset center, int sides, double radius) {
  final path = Path();
  final step = 2 * math.pi / sides;
  for (var i = 0; i < sides; i++) {
    final angle = i * step - math.pi / 2;
    final point = pointOnCircle(center, radius, angle);
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  return path;
}

/// Criar path de coração
Path createHeartPath(Offset center, double size) {
  final path = Path();
  final w = size;
  final h = size;
  path.moveTo(center.dx, center.dy + h * 0.35);
  path.cubicTo(
    center.dx - w * 0.5, center.dy - h * 0.2,
    center.dx - w * 0.5, center.dy - h * 0.5,
    center.dx, center.dy - h * 0.2,
  );
  path.cubicTo(
    center.dx + w * 0.5, center.dy - h * 0.5,
    center.dx + w * 0.5, center.dy - h * 0.2,
    center.dx, center.dy + h * 0.35,
  );
  path.close();
  return path;
}
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

- [Padrões reutilizáveis de CustomPainter](./references/patterns.md)
- [Flutter CustomPainter API](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
- [Flutter Canvas API](https://api.flutter.dev/flutter/dart-ui/Canvas-class.html)
- [Flutter Path API](https://api.flutter.dev/flutter/dart-ui/Path-class.html)
- [PathOperation enum](https://api.flutter.dev/flutter/dart-ui/PathOperation.html)
- [BlendMode enum](https://api.flutter.dev/flutter/dart-ui/BlendMode.html)
- [Paths in Flutter: A Visual Guide](https://medium.com/flutter-community/paths-in-flutter-a-visual-guide-6c906464dcd0)
- [Definitive Flutter Painting Guide](https://getstream.io/blog/definitive-flutter-painting-guide/)
- [SVG to Flutter Path](https://www.flutterclutter.dev/flutter/tutorials/svg-to-flutter-path/2020/678/)
- [Very Good Ventures — Mastering CustomPainter](https://verygood.ventures/blog/mastering-custompainter-in-flutter-from-svgs-to-racetracks/)


---

**Última atualização**: 28 de março de 2026
