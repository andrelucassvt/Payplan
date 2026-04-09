import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/util/entity/devedores_entity.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

const _kAccent = Color(0xFF5C5FEF);

class GraficosView extends StatefulWidget {
  const GraficosView({
    required this.dividas,
    required this.devedores,
    required this.homeCubit,
    required this.screenshotDividasController,
    required this.screenshotDevedoresController,
    super.key,
  });
  final List<DividaEntity> dividas;
  final List<DevedoresEntity> devedores;
  final ScreenshotController screenshotDividasController;
  final ScreenshotController screenshotDevedoresController;
  final HomeCubit homeCubit;

  @override
  State<GraficosView> createState() => _GraficosViewState();
}

class _GraficosViewState extends State<GraficosView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeCard1;
  late final Animation<Offset> _slideCard1;
  late final Animation<double> _fadeCard2;
  late final Animation<Offset> _slideCard2;

  int _touchedDividaIndex = -1;
  int _touchedDevedorIndex = -1;

  HomeState get state => widget.homeCubit.state;

  double _valorFatura(DividaEntity e) {
    final faturaValor =
        e.faturaDoMes(state.anoAtual, state.mesAtual.id)?.valor ?? 0;
    return faturaValor +
        e.totalSubDividasDoMes(state.anoAtual, state.mesAtual.id);
  }

  double get valorTotalFatura =>
      widget.dividas.map(_valorFatura).fold(0, (prev, el) => prev + el);

  double get valorTotalDevedores =>
      widget.devedores.map((e) => e.valor).fold(0, (prev, el) => prev + el);

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeCard1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    _slideCard1 = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    _fadeCard2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );
    _slideCard2 = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dividasFiltered =
        widget.dividas.where((e) => _valorFatura(e) > 0).toList();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: Text(AppStrings.graficoGastos),
      ),
      body: valorTotalFatura == 0 && valorTotalDevedores == 0
          ? const _EmptyState()
          : SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Column(
                  children: [
                    if (valorTotalFatura != 0)
                      FadeTransition(
                        opacity: _fadeCard1,
                        child: SlideTransition(
                          position: _slideCard1,
                          child: _ChartCard(
                            title:
                                '${AppStrings.dividas} · ${state.mesAtual.nome} ${state.anoAtual}',
                            total: valorTotalFatura,
                            onShare: () =>
                                _share(widget.screenshotDividasController),
                            screenshotController:
                                widget.screenshotDividasController,
                            screenshotBackground:
                                Theme.of(context).scaffoldBackgroundColor,
                            chart: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 40,
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        _touchedDividaIndex = -1;
                                        return;
                                      }
                                      _touchedDividaIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                sections: dividasFiltered
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => PieChartSectionData(
                                        radius: _touchedDividaIndex == entry.key
                                            ? 96
                                            : 80,
                                        value: _valorFatura(entry.value),
                                        title: '',
                                        color: entry.value.cor,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            legend: dividasFiltered
                                .asMap()
                                .entries
                                .map(
                                  (entry) => _LegendItem(
                                    color: entry.value.cor,
                                    label: entry.value.nome,
                                    value: _valorFatura(entry.value).real,
                                    isHighlighted:
                                        _touchedDividaIndex == entry.key,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    if (valorTotalFatura != 0 && valorTotalDevedores != 0)
                      const SizedBox(height: 16),
                    if (valorTotalDevedores != 0)
                      FadeTransition(
                        opacity: _fadeCard2,
                        child: SlideTransition(
                          position: _slideCard2,
                          child: _ChartCard(
                            title: AppStrings.devedores,
                            total: valorTotalDevedores,
                            onShare: () =>
                                _share(widget.screenshotDevedoresController),
                            screenshotController:
                                widget.screenshotDevedoresController,
                            screenshotBackground:
                                Theme.of(context).scaffoldBackgroundColor,
                            chart: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 40,
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        _touchedDevedorIndex = -1;
                                        return;
                                      }
                                      _touchedDevedorIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                sections: widget.devedores
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => PieChartSectionData(
                                        radius: _touchedDevedorIndex == e.key
                                            ? 96
                                            : 80,
                                        value: e.value.valor,
                                        title: '',
                                        color: Colors.primaries[
                                            e.key % Colors.primaries.length],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            legend: widget.devedores
                                .asMap()
                                .entries
                                .map(
                                  (e) => _LegendItem(
                                    color: Colors.primaries[
                                        e.key % Colors.primaries.length],
                                    label: e.value.nome,
                                    value: e.value.valor.real,
                                    isHighlighted:
                                        _touchedDevedorIndex == e.key,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _share(ScreenshotController controller) async {
    final result = await controller.capture();
    if (result == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = await File('${directory.path}/image.png').create();
    await imagePath.writeAsBytes(result);
    await Share.shareXFiles(
      [XFile(imagePath.path)],
      text: AppStrings.baixePayplan,
    );
  }
}

// ---------------------------------------------------------------------------

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.total,
    required this.chart,
    required this.legend,
    required this.onShare,
    required this.screenshotController,
    required this.screenshotBackground,
  });

  final String title;
  final double total;
  final Widget chart;
  final List<Widget> legend;
  final VoidCallback onShare;
  final ScreenshotController screenshotController;
  final Color screenshotBackground;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Screenshot(
      controller: screenshotController,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withValues(alpha: 0.07),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onShare,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.ios_share_outlined,
                      size: 18,
                      color: _kAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: total),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, value, _) => Text(
                value.real,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: chart,
            ),
            const SizedBox(height: 20),
            ...legend,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  final Color color;
  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        vertical: 5,
        horizontal: isHighlighted ? 8 : 0,
      ),
      decoration: BoxDecoration(
        color:
            isHighlighted ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isHighlighted ? 14 : 12,
            height: isHighlighted ? 14 : 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isHighlighted ? 14 : 13,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                color: cs.onSurface,
              ),
              child: Text(label),
            ),
          ),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: isHighlighted ? 14 : 13,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? color : cs.onSurface,
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pie_chart_outline_rounded,
              size: 36,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhum dado para exibir',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione dívidas ou devedores\npara ver os gráficos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
