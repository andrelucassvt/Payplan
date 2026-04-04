# Padrões Reutilizáveis de CustomPainter

Catálogo de painters prontos para uso ou adaptação. Cada padrão segue as regras da skill: objetos `Paint`/`Path` criados dentro de `paint()`, `shouldRepaint` comparando apenas propriedades relevantes, e suporte a `const` quando possível.

---

## 1. Indicador de Progresso Circular (Donut)

```dart
class DonutProgressPainter extends CustomPainter {
  const DonutProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 10,
  });

  final double progress;      // 0.0 a 1.0
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Track (fundo)
    canvas.drawCircle(center, radius, trackPaint);

    // Progresso
    canvas.drawArc(
      rect,
      -math.pi / 2,                // começa do topo
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(DonutProgressPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.strokeWidth != strokeWidth;
}
```

---

## 2. Donut com Gradiente e Label Central

```dart
class GradientDonutPainter extends CustomPainter {
  const GradientDonutPainter({
    required this.progress,
    required this.gradientColors,
    required this.trackColor,
    required this.label,
    this.strokeWidth = 12,
    this.labelStyle = const TextStyle(
      color: Colors.black,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  });

  final double progress;
  final List<Color> gradientColors;
  final Color trackColor;
  final String label;
  final double strokeWidth;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Arco com gradiente
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final gradientPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
        colors: gradientColors,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, gradientPaint);

    // Texto central
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: labelStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(GradientDonutPainter old) =>
      old.progress != progress ||
      old.label != label ||
      old.trackColor != trackColor;
}
```

---

## 3. Onda (Wave)

```dart
class WavePainter extends CustomPainter {
  const WavePainter({
    required this.animationValue,
    required this.color,
    this.waveHeight = 20,
    this.frequency = 1.5,
  });

  final double animationValue; // 0.0 a 1.0 vindo do AnimationController
  final Color color;
  final double waveHeight;
  final double frequency;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 +
          waveHeight *
              math.sin(
                (x / size.width * 2 * math.pi * frequency) +
                    (animationValue * 2 * math.pi),
              );
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter old) =>
      old.animationValue != animationValue ||
      old.color != color ||
      old.waveHeight != waveHeight;
}
```

---

## 4. Múltiplas Ondas Sobrepostas (Multi-Wave)

```dart
class MultiWavePainter extends CustomPainter {
  const MultiWavePainter({
    required this.animationValue,
    required this.waves,
  });

  final double animationValue;
  final List<WaveConfig> waves;

  @override
  void paint(Canvas canvas, Size size) {
    for (final wave in waves) {
      final path = Path();
      path.moveTo(0, size.height);

      for (double x = 0; x <= size.width; x++) {
        final y = wave.baseY * size.height +
            wave.amplitude *
                math.sin(
                  (x / size.width * 2 * math.pi * wave.frequency) +
                      (animationValue * 2 * math.pi) +
                      wave.phaseOffset,
                );
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = wave.color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(MultiWavePainter old) =>
      old.animationValue != animationValue;
}

// Configuração de cada onda
class WaveConfig {
  const WaveConfig({
    required this.color,
    this.amplitude = 20,
    this.frequency = 1.5,
    this.baseY = 0.5,
    this.phaseOffset = 0,
  });

  final Color color;
  final double amplitude;
  final double frequency;
  final double baseY;     // 0.0 = topo, 1.0 = base
  final double phaseOffset;
}
```

---

## 5. Gráfico de Barras com Labels e Animação

```dart
class AnimatedBarChartPainter extends CustomPainter {
  const AnimatedBarChartPainter({
    required this.values,
    required this.labels,
    required this.barColor,
    required this.animationValue,
    this.barSpacing = 8,
    this.labelStyle = const TextStyle(color: Colors.grey, fontSize: 10),
    this.valueStyle = const TextStyle(color: Colors.black, fontSize: 11),
    this.showValues = true,
    this.borderRadius = 4,
  });

  final List<double> values;       // 0.0 a 1.0 (normalizada)
  final List<String> labels;
  final Color barColor;
  final double animationValue;     // 0.0 a 1.0
  final double barSpacing;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final bool showValues;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const labelAreaHeight = 24.0;
    const valueAreaHeight = 20.0;
    final chartHeight = size.height - labelAreaHeight - valueAreaHeight;
    final barWidth = (size.width - (barSpacing * (values.length - 1))) /
        values.length;

    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (var i = 0; i < values.length; i++) {
      final animatedValue = values[i].clamp(0.0, 1.0) * animationValue;
      final barHeight = chartHeight * animatedValue;
      final left = i * (barWidth + barSpacing);
      final top = valueAreaHeight + chartHeight - barHeight;

      // Barra
      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      );
      canvas.drawRRect(rrect, barPaint);

      // Valor acima da barra
      if (showValues && animationValue > 0.5) {
        final valueText = '${(values[i] * 100).toStringAsFixed(0)}%';
        final valuePainter = TextPainter(
          text: TextSpan(text: valueText, style: valueStyle),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: barWidth);

        valuePainter.paint(
          canvas,
          Offset(
            left + (barWidth - valuePainter.width) / 2,
            top - valuePainter.height - 4,
          ),
        );
      }

      // Label abaixo
      if (i < labels.length) {
        final labelPainter = TextPainter(
          text: TextSpan(text: labels[i], style: labelStyle),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: barWidth + barSpacing);

        labelPainter.paint(
          canvas,
          Offset(
            left + (barWidth - labelPainter.width) / 2,
            size.height - labelAreaHeight + 4,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(AnimatedBarChartPainter old) =>
      old.values != values ||
      old.animationValue != animationValue ||
      old.barColor != barColor;
}
```

---

## 6. Gráfico de Linha com Gradiente e Pontos

```dart
class LineChartPainter extends CustomPainter {
  const LineChartPainter({
    required this.dataPoints,
    required this.lineColor,
    required this.fillGradientColors,
    required this.animationValue,
    this.strokeWidth = 2.5,
    this.pointRadius = 4,
    this.showPoints = true,
    this.showGrid = true,
    this.gridColor = const Color(0xFFE0E0E0),
    this.gridLines = 4,
  });

  final List<Offset> dataPoints;    // x: 0.0–1.0, y: 0.0–1.0
  final Color lineColor;
  final List<Color> fillGradientColors;
  final double animationValue;
  final double strokeWidth;
  final double pointRadius;
  final bool showPoints;
  final bool showGrid;
  final Color gridColor;
  final int gridLines;

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final padding = EdgeInsets.only(
      left: 8, right: 8, top: 16, bottom: 8,
    );
    final chartRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.horizontal,
      size.height - padding.vertical,
    );

    // Grid horizontal
    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      for (var i = 0; i <= gridLines; i++) {
        final y = chartRect.top +
            (chartRect.height / gridLines) * i;
        canvas.drawLine(
          Offset(chartRect.left, y),
          Offset(chartRect.right, y),
          gridPaint,
        );
      }
    }

    // Converter pontos normalizados para coordenadas de tela
    final points = dataPoints.map((p) {
      return Offset(
        chartRect.left + p.dx * chartRect.width,
        chartRect.bottom - p.dy * chartRect.height * animationValue,
      );
    }).toList();

    // Criar path suave usando Catmull-Rom → Cubic Bezier
    final linePath = _smoothPath(points);

    // Preencher área sob a curva com gradiente
    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, chartRect.bottom)
      ..lineTo(points.first.dx, chartRect.bottom)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: fillGradientColors,
        ).createShader(chartRect)
        ..style = PaintingStyle.fill,
    );

    // Linha
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Pontos
    if (showPoints) {
      for (final point in points) {
        // Sombra do ponto
        canvas.drawCircle(
          point,
          pointRadius + 2,
          Paint()..color = lineColor.withOpacity(0.3),
        );
        // Ponto branco
        canvas.drawCircle(
          point,
          pointRadius,
          Paint()..color = Colors.white,
        );
        // Borda do ponto
        canvas.drawCircle(
          point,
          pointRadius,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  Path _smoothPath(List<Offset> points) {
    if (points.length < 2) return Path();

    final path = Path()..moveTo(points[0].dx, points[0].dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

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

  @override
  bool shouldRepaint(LineChartPainter old) =>
      old.dataPoints != dataPoints ||
      old.animationValue != animationValue ||
      old.lineColor != lineColor;
}
```

---

## 7. Gráfico de Pizza (Pie Chart) com Labels

```dart
class PieChartPainter extends CustomPainter {
  const PieChartPainter({
    required this.slices,
    required this.animationValue,
    this.holeRadius = 0,
    this.gap = 2,
    this.labelStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
  });

  final List<PieSlice> slices;
  final double animationValue;
  final double holeRadius;     // 0 = pizza cheia, >0 = donut
  final double gap;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 4;
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    final gapAngle = gap / radius; // converter pixels para radianos

    for (final slice in slices) {
      final sweepAngle =
          (slice.value / total) * 2 * math.pi * animationValue - gapAngle;
      if (sweepAngle <= 0) {
        startAngle += (slice.value / total) * 2 * math.pi * animationValue;
        continue;
      }

      // Path da fatia
      final path = Path();
      if (holeRadius > 0) {
        // Donut
        path.addArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
        );
        path.arcTo(
          Rect.fromCircle(center: center, radius: holeRadius),
          startAngle + sweepAngle,
          -sweepAngle,
          false,
        );
        path.close();
      } else {
        // Pizza
        path.moveTo(center.dx, center.dy);
        path.arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
        );
        path.close();
      }

      canvas.drawPath(path, Paint()..color = slice.color);

      // Label na fatia (se animação quase completa)
      if (animationValue > 0.8 && slice.label != null) {
        final midAngle = startAngle + sweepAngle / 2;
        final labelRadius = holeRadius > 0
            ? (radius + holeRadius) / 2
            : radius * 0.65;
        final labelPos = Offset(
          center.dx + labelRadius * math.cos(midAngle),
          center.dy + labelRadius * math.sin(midAngle),
        );

        final textPainter = TextPainter(
          text: TextSpan(text: slice.label, style: labelStyle),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            labelPos.dx - textPainter.width / 2,
            labelPos.dy - textPainter.height / 2,
          ),
        );
      }

      startAngle += (slice.value / total) * 2 * math.pi * animationValue;
    }
  }

  @override
  bool shouldRepaint(PieChartPainter old) =>
      old.slices != slices || old.animationValue != animationValue;
}

class PieSlice {
  const PieSlice({
    required this.value,
    required this.color,
    this.label,
  });

  final double value;
  final Color color;
  final String? label;
}
```

---

## 8. Gauge / Velocímetro

```dart
class GaugePainter extends CustomPainter {
  const GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.trackColor,
    required this.valueColor,
    this.startAngle = 135,    // graus
    this.sweepAngle = 270,    // graus
    this.strokeWidth = 14,
    this.showTicks = true,
    this.tickCount = 10,
    this.tickColor = const Color(0xFF9E9E9E),
    this.needleColor = const Color(0xFF212121),
    this.labelStyle = const TextStyle(color: Colors.black87, fontSize: 28),
  });

  final double value;
  final double minValue;
  final double maxValue;
  final Color trackColor;
  final Color valueColor;
  final double startAngle;
  final double sweepAngle;
  final double strokeWidth;
  final bool showTicks;
  final int tickCount;
  final Color tickColor;
  final Color needleColor;
  final TextStyle labelStyle;

  double get _startRad => startAngle * math.pi / 180;
  double get _sweepRad => sweepAngle * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2 - 20;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawArc(
      rect,
      _startRad,
      _sweepRad,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Valor
    final normalized = ((value - minValue) / (maxValue - minValue))
        .clamp(0.0, 1.0);
    canvas.drawArc(
      rect,
      _startRad,
      _sweepRad * normalized,
      false,
      Paint()
        ..color = valueColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Ticks
    if (showTicks) {
      final tickPaint = Paint()
        ..color = tickColor
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      for (var i = 0; i <= tickCount; i++) {
        final angle = _startRad + (_sweepRad / tickCount) * i;
        final isMainTick = i % 2 == 0;
        final tickLength = isMainTick ? 12.0 : 6.0;
        final outerPoint = Offset(
          center.dx + (radius + strokeWidth / 2 + 4) * math.cos(angle),
          center.dy + (radius + strokeWidth / 2 + 4) * math.sin(angle),
        );
        final innerPoint = Offset(
          center.dx +
              (radius + strokeWidth / 2 + 4 + tickLength) * math.cos(angle),
          center.dy +
              (radius + strokeWidth / 2 + 4 + tickLength) * math.sin(angle),
        );
        canvas.drawLine(outerPoint, innerPoint, tickPaint);
      }
    }

    // Agulha
    final needleAngle = _startRad + _sweepRad * normalized;
    final needleLength = radius - 10;
    final needleTip = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    canvas.drawLine(
      center,
      needleTip,
      Paint()
        ..color = needleColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Centro da agulha
    canvas.drawCircle(center, 6, Paint()..color = needleColor);
    canvas.drawCircle(
      center, 3,
      Paint()..color = Colors.white,
    );

    // Label central
    final displayValue = value.toStringAsFixed(0);
    final textPainter = TextPainter(
      text: TextSpan(text: displayValue, style: labelStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + radius * 0.35,
      ),
    );
  }

  @override
  bool shouldRepaint(GaugePainter old) =>
      old.value != value ||
      old.trackColor != trackColor ||
      old.valueColor != valueColor;
}
```

---

## 9. Radar / Spider Chart

```dart
class RadarChartPainter extends CustomPainter {
  const RadarChartPainter({
    required this.data,
    required this.maxValue,
    required this.labels,
    required this.dataColor,
    required this.animationValue,
    this.gridColor = const Color(0xFFE0E0E0),
    this.gridLevels = 4,
    this.labelStyle = const TextStyle(color: Colors.black54, fontSize: 11),
  });

  final List<double> data;
  final double maxValue;
  final List<String> labels;
  final Color dataColor;
  final double animationValue;
  final Color gridColor;
  final int gridLevels;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 30;
    final sides = data.length;
    final angleStep = 2 * math.pi / sides;

    // Grid
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var level = 1; level <= gridLevels; level++) {
      final levelRadius = radius * level / gridLevels;
      final gridPath = Path();
      for (var i = 0; i < sides; i++) {
        final angle = i * angleStep - math.pi / 2;
        final point = Offset(
          center.dx + levelRadius * math.cos(angle),
          center.dy + levelRadius * math.sin(angle),
        );
        if (i == 0) {
          gridPath.moveTo(point.dx, point.dy);
        } else {
          gridPath.lineTo(point.dx, point.dy);
        }
      }
      gridPath.close();
      canvas.drawPath(gridPath, gridPaint);
    }

    // Eixos
    for (var i = 0; i < sides; i++) {
      final angle = i * angleStep - math.pi / 2;
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, gridPaint);
    }

    // Dados
    final dataPath = Path();
    for (var i = 0; i < sides; i++) {
      final angle = i * angleStep - math.pi / 2;
      final normalizedValue =
          (data[i] / maxValue).clamp(0.0, 1.0) * animationValue;
      final point = Offset(
        center.dx + radius * normalizedValue * math.cos(angle),
        center.dy + radius * normalizedValue * math.sin(angle),
      );
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();

    // Fill
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = dataColor.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );

    // Stroke
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = dataColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // Pontos nos vértices
    for (var i = 0; i < sides; i++) {
      final angle = i * angleStep - math.pi / 2;
      final normalizedValue =
          (data[i] / maxValue).clamp(0.0, 1.0) * animationValue;
      final point = Offset(
        center.dx + radius * normalizedValue * math.cos(angle),
        center.dy + radius * normalizedValue * math.sin(angle),
      );
      canvas.drawCircle(point, 4, Paint()..color = dataColor);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }

    // Labels
    for (var i = 0; i < sides && i < labels.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final labelRadius = radius + 16;
      final labelPos = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          labelPos.dx - textPainter.width / 2,
          labelPos.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(RadarChartPainter old) =>
      old.data != data || old.animationValue != animationValue;
}
```

---

## 10. Partículas (Particle System)

```dart
class ParticlePainter extends CustomPainter {
  const ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  final List<Particle> particles;
  final double animationValue; // 0.0 a 1.0, incrementa a cada frame

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final age = (animationValue - p.birthTime).abs() % 1.0;
      final opacity = (1.0 - age).clamp(0.0, 1.0);
      final currentRadius = p.radius * (0.5 + age * 0.5);

      // Posição com movimento
      final x = p.startX + p.velocityX * age * size.width;
      final y = p.startY + p.velocityY * age * size.height;

      if (x < 0 || x > size.width || y < 0 || y > size.height) continue;

      canvas.drawCircle(
        Offset(x, y),
        currentRadius,
        Paint()..color = p.color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter old) =>
      old.animationValue != animationValue;
}

class Particle {
  const Particle({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.radius,
    required this.color,
    required this.birthTime,
  });

  final double startX;
  final double startY;
  final double velocityX;   // fração do width por ciclo
  final double velocityY;   // fração do height por ciclo
  final double radius;
  final Color color;
  final double birthTime;   // 0.0 a 1.0

  static List<Particle> generate(int count, Size size, {Color? color}) {
    final rng = math.Random();
    return List.generate(count, (_) {
      return Particle(
        startX: rng.nextDouble() * size.width,
        startY: rng.nextDouble() * size.height,
        velocityX: (rng.nextDouble() - 0.5) * 0.2,
        velocityY: (rng.nextDouble() - 0.5) * 0.2,
        radius: rng.nextDouble() * 3 + 1,
        color: color ?? Color.fromRGBO(
          rng.nextInt(256), rng.nextInt(256), rng.nextInt(256), 1,
        ),
        birthTime: rng.nextDouble(),
      );
    });
  }
}
```

---

## 11. Stroke Drawing Animation (Desenho Progressivo)

```dart
class StrokeDrawingPainter extends CustomPainter {
  const StrokeDrawingPainter({
    required this.path,
    required this.progress,
    required this.color,
    this.strokeWidth = 3,
    this.showDot = true,
    this.dotColor,
    this.dotRadius = 5,
  });

  final Path path;
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool showDot;
  final Color? dotColor;
  final double dotRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final metric in path.computeMetrics()) {
      final len = metric.length * progress.clamp(0.0, 1.0);
      final extractedPath = metric.extractPath(0, len);
      canvas.drawPath(extractedPath, paint);

      // Ponto na ponta do desenho
      if (showDot && progress > 0 && progress < 1) {
        final tangent = metric.getTangentForOffset(len);
        if (tangent != null) {
          canvas.drawCircle(
            tangent.position,
            dotRadius,
            Paint()..color = dotColor ?? color,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(StrokeDrawingPainter old) =>
      old.progress != progress || old.color != color;
}
```

---

## 12. Neumorphic Shape

```dart
class NeumorphicPainter extends CustomPainter {
  const NeumorphicPainter({
    required this.backgroundColor,
    this.borderRadius = 20,
    this.depth = 6,
    this.blurRadius = 10,
    this.isPressed = false,
  });

  final Color backgroundColor;
  final double borderRadius;
  final double depth;
  final double blurRadius;
  final bool isPressed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      depth + blurRadius,
      depth + blurRadius,
      size.width - 2 * (depth + blurRadius),
      size.height - 2 * (depth + blurRadius),
    );
    final rrect = RRect.fromRectAndRadius(
      rect, Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);

    final d = isPressed ? -depth : depth;

    // Sombra escura (inferior direita)
    canvas.save();
    canvas.translate(d, d);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius),
    );
    canvas.restore();

    // Sombra clara (superior esquerda)
    canvas.save();
    canvas.translate(-d, -d);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius),
    );
    canvas.restore();

    // Forma principal
    canvas.drawPath(path, Paint()..color = backgroundColor);
  }

  @override
  bool shouldRepaint(NeumorphicPainter old) =>
      old.isPressed != isPressed ||
      old.backgroundColor != backgroundColor;
}
```

---

## 13. Halo / Pulse (Animado)

```dart
class PulsePainter extends CustomPainter {
  const PulsePainter({
    required this.animationValue,
    required this.color,
    this.rings = 3,
  });

  final double animationValue; // 0.0 a 1.0
  final Color color;
  final int rings;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;

    // Múltiplos anéis com offsets
    for (var i = 0; i < rings; i++) {
      final ringProgress =
          ((animationValue + i / rings) % 1.0).clamp(0.0, 1.0);
      final opacity = (1.0 - ringProgress).clamp(0.0, 1.0);

      canvas.drawCircle(
        center,
        maxRadius * ringProgress,
        Paint()
          ..color = color.withOpacity(opacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Círculo central fixo
    canvas.drawCircle(
      center,
      maxRadius * 0.15,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(PulsePainter old) =>
      old.animationValue != animationValue;
}
```

---

## 14. Gradiente Animado (Sweep)

```dart
class SweepGradientPainter extends CustomPainter {
  const SweepGradientPainter({
    required this.animationValue,
    required this.colors,
  });

  final double animationValue;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    final paint = Paint()
      ..shader = SweepGradient(
        colors: colors,
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(animationValue * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(SweepGradientPainter old) =>
      old.animationValue != animationValue;
}
```

---

## 15. ClipPath — Header Ondulado

```dart
class WaveHeaderClipper extends CustomClipper<Path> {
  const WaveHeaderClipper({this.waveHeight = 40});
  final double waveHeight;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - waveHeight)
      ..quadraticBezierTo(
        size.width / 4, size.height,
        size.width / 2, size.height - waveHeight,
      )
      ..quadraticBezierTo(
        3 * size.width / 4, size.height - 2 * waveHeight,
        size.width, size.height - waveHeight,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(WaveHeaderClipper old) => old.waveHeight != waveHeight;
}

// Uso:
ClipPath(
  clipper: WaveHeaderClipper(waveHeight: 40),
  child: Container(
    height: 200,
    color: Theme.of(context).colorScheme.primary,
  ),
)
```

---

## 16. Linha Pontilhada / Tracejada

```dart
/// Desenha uma linha tracejada entre dois pontos
void drawDashedLine(
  Canvas canvas,
  Offset start,
  Offset end,
  Color color, {
  double dashWidth = 6,
  double dashSpace = 4,
  double strokeWidth = 1.5,
}) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final totalLength = (end - start).distance;
  final direction = (end - start) / totalLength;
  var drawn = 0.0;

  while (drawn < totalLength) {
    final dashEnd = math.min(drawn + dashWidth, totalLength);
    canvas.drawLine(
      start + direction * drawn,
      start + direction * dashEnd,
      paint,
    );
    drawn += dashWidth + dashSpace;
  }
}

/// Converte qualquer Path em tracejado
Path createDashedPath(
  Path source, {
  double dashWidth = 6,
  double dashSpace = 4,
}) {
  final dashedPath = Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final end = math.min(distance + dashWidth, metric.length);
      dashedPath.addPath(
        metric.extractPath(distance, end),
        Offset.zero,
      );
      distance += dashWidth + dashSpace;
    }
  }
  return dashedPath;
}
```

---

## 17. Progress Bar Linear com Gradiente e Rounding

```dart
class LinearProgressPainter extends CustomPainter {
  const LinearProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.gradientColors,
    this.height = 8,
    this.borderRadius = 4,
  });

  final double progress;
  final Color trackColor;
  final List<Color> gradientColors;
  final double height;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final y = (size.height - height) / 2;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, y, size.width, height),
      Radius.circular(borderRadius),
    );

    // Track
    canvas.drawRRect(trackRect, Paint()..color = trackColor);

    // Progress
    final progressWidth = size.width * progress.clamp(0.0, 1.0);
    if (progressWidth > 0) {
      final progressRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, y, progressWidth, height),
        Radius.circular(borderRadius),
      );

      canvas.drawRRect(
        progressRect,
        Paint()
          ..shader = LinearGradient(colors: gradientColors)
              .createShader(Rect.fromLTWH(0, y, size.width, height)),
      );
    }
  }

  @override
  bool shouldRepaint(LinearProgressPainter old) =>
      old.progress != progress || old.trackColor != trackColor;
}
```

---

## 18. Formas com Rotação Dinâmica

```dart
class RotatingShapesPainter extends CustomPainter {
  const RotatingShapesPainter({
    required this.animationValue,
    required this.color,
    this.shapeCount = 6,
  });

  final double animationValue;
  final Color color;
  final int shapeCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbitRadius = size.shortestSide / 3;

    for (var i = 0; i < shapeCount; i++) {
      final angle = (i / shapeCount) * 2 * math.pi +
          animationValue * 2 * math.pi;
      final shapeCenter = Offset(
        center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle),
      );

      // Cada forma rotaciona independentemente
      canvas.save();
      canvas.translate(shapeCenter.dx, shapeCenter.dy);
      canvas.rotate(animationValue * math.pi * 2 * (i.isEven ? 1 : -1));

      final shapeSize = 12.0 + (i * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: shapeSize,
            height: shapeSize,
          ),
          Radius.circular(shapeSize * 0.2),
        ),
        Paint()
          ..color = color.withOpacity(0.5 + (i / shapeCount) * 0.5),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(RotatingShapesPainter old) =>
      old.animationValue != animationValue;
}
```

---

## 19. Path Combine — Formas com Recorte

```dart
class CombinedShapePainter extends CustomPainter {
  const CombinedShapePainter({
    required this.color,
    required this.operation,
  });

  final Color color;
  final PathOperation operation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 3;

    final circle1 = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx - r * 0.3, center.dy),
        radius: r,
      ));
    final circle2 = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx + r * 0.3, center.dy),
        radius: r,
      ));

    final combined = Path.combine(operation, circle1, circle2);

    // Sombra
    canvas.drawShadow(combined, Colors.black, 4, true);

    // Forma
    canvas.drawPath(combined, Paint()..color = color);

    // Contorno
    canvas.drawPath(
      combined,
      Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(CombinedShapePainter old) =>
      old.operation != operation || old.color != color;
}
```

---

## 20. Indicador de Loading Circular com Traço Animado

```dart
class SpinnerPainter extends CustomPainter {
  const SpinnerPainter({
    required this.animationValue,
    required this.color,
    this.strokeWidth = 4,
  });

  final double animationValue;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // O arco cresce e encolhe ciclicamente
    final startAngle = animationValue * 2 * math.pi;
    final sweepAngle = math.pi * 0.5 +
        math.pi * 1.0 * math.sin(animationValue * 2 * math.pi).abs();

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(SpinnerPainter old) =>
      old.animationValue != animationValue;
}
```

---

## Dicas de Performance

| Cenário | Recomendação |
|---------|-------------|
| Painter não muda | `shouldRepaint` retorna `false` |
| Painter muda frequentemente (animação) | Envolva com `RepaintBoundary` |
| Múltiplos painters independentes | Um `RepaintBoundary` por painter |
| Criação de objetos no `paint()` | OK para `Paint` e `Path` — Flutter otimiza por frame |
| Texto no canvas | Crie e chame `.layout()` sempre em `paint()` |
| Listas longas com painter por item | Use `RepaintBoundary` no item do `ListView.builder` |
| Desenho estático complexo | Use `PictureRecorder` para cache |
| Muitos pontos (>1000) | Use `drawRawPoints` com `Float32List` |
| Paths que não mudam | Pré-compute como propriedade do painter |
| `saveLayer` | Evite — é caro para GPU; prefira `save/restore` |
