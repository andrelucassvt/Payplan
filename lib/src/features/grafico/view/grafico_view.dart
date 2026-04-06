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

class _GraficosViewState extends State<GraficosView> {
  HomeState get state => widget.homeCubit.state;

  // Fix: use the faturaDoMes helper to avoid the FaturaMensalModel type mismatch
  double _valorFatura(DividaEntity e) =>
      e.faturaDoMes(state.anoAtual, state.mesAtual.id)?.valor ?? 0;

  double get valorTotalFatura =>
      widget.dividas.map(_valorFatura).fold(0, (prev, el) => prev + el);

  double get valorTotalDevedores =>
      widget.devedores.map((e) => e.valor).fold(0, (prev, el) => prev + el);

  @override
  Widget build(BuildContext context) {
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
          ? _EmptyState()
          : SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Column(
                  children: [
                    if (valorTotalFatura != 0)
                      _ChartCard(
                        title:
                            '${AppStrings.dividas} · ${state.mesAtual.nome} ${state.anoAtual}',
                        total: valorTotalFatura.real,
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
                            sections: widget.dividas
                                .where((e) => _valorFatura(e) > 0)
                                .map(
                                  (e) => PieChartSectionData(
                                    radius: 80,
                                    value: _valorFatura(e),
                                    title: '',
                                    color: e.cor,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        legend: widget.dividas
                            .where((e) => _valorFatura(e) > 0)
                            .map(
                              (e) => _LegendItem(
                                color: e.cor,
                                label: e.nome,
                                value: _valorFatura(e).real,
                              ),
                            )
                            .toList(),
                      ),
                    if (valorTotalFatura != 0 && valorTotalDevedores != 0)
                      const SizedBox(height: 16),
                    if (valorTotalDevedores != 0)
                      _ChartCard(
                        title: AppStrings.devedores,
                        total: valorTotalDevedores.real,
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
                            sections: widget.devedores
                                .asMap()
                                .entries
                                .map(
                                  (e) => PieChartSectionData(
                                    radius: 80,
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
                                color: Colors
                                    .primaries[e.key % Colors.primaries.length],
                                label: e.value.nome,
                                value: e.value.valor.real,
                              ),
                            )
                            .toList(),
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
  final String total;
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
            Text(
              total,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.5,
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
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
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
