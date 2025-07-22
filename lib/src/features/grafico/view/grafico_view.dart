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
  int touchedIndex = -1;
  HomeState get state => widget.homeCubit.state;

  double get valorTotalFatura => widget.dividas
      .map((e) => e.faturas
          .firstWhere(
            (element) =>
                element.ano == state.anoAtual &&
                element.mes == state.mesAtual.id,
            orElse: () => FaturaMensalEntity(
              ano: state.anoAtual,
              mes: state.mesAtual.id,
              valor: 0,
              pago: false,
            ),
          )
          .valor)
      .fold(0, (previousValue, element) => previousValue + element);

  double get valorTotalDevedores => widget.devedores
      .map((e) => e.valor)
      .fold(0, (previousValue, element) => previousValue + element);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          AppStrings.graficoGastos,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: valorTotalFatura == 0 && valorTotalDevedores == 0
          ? Center(
              child: Text(
                'Vazio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .7),
                  fontSize: 20,
                ),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    Screenshot(
                      controller: widget.screenshotDividasController,
                      child: Container(
                        color: Colors.black,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (valorTotalFatura != 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    '${AppStrings.dividas} (${state.mesAtual.nome} ${state.anoAtual})',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: .7),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final result = await widget
                                          .screenshotDividasController
                                          .capture();
                                      if (result != null) {
                                        final directory =
                                            await getApplicationDocumentsDirectory();
                                        final imagePath = await File(
                                                '${directory.path}/image.png')
                                            .create();
                                        await imagePath.writeAsBytes(result);
                                        await Share.shareXFiles(
                                          [
                                            XFile(imagePath.path),
                                          ],
                                          text: AppStrings.baixePayplan,
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      Icons.share,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                valorTotalFatura.real,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Center(
                                child: SizedBox(
                                  height: 300,
                                  width: 300,
                                  child: PieChart(
                                    PieChartData(
                                        sections: widget.dividas.map((e) {
                                      return PieChartSectionData(
                                        radius: 100,
                                        value: (e.faturas
                                            .firstWhere(
                                              (element) =>
                                                  element.ano ==
                                                      state.anoAtual &&
                                                  element.mes ==
                                                      state.mesAtual.id,
                                              orElse: () => FaturaMensalEntity(
                                                ano: state.anoAtual,
                                                mes: state.mesAtual.id,
                                                valor: 0,
                                                pago: false,
                                              ),
                                            )
                                            .valor),
                                        title: e.faturas
                                            .firstWhere(
                                              (element) =>
                                                  element.ano ==
                                                      state.anoAtual &&
                                                  element.mes ==
                                                      state.mesAtual.id,
                                              orElse: () => FaturaMensalEntity(
                                                ano: state.anoAtual,
                                                mes: state.mesAtual.id,
                                                valor: 0,
                                                pago: false,
                                              ),
                                            )
                                            .valor
                                            .real,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        showTitle: true,
                                        color: e.cor,
                                      );
                                    }).toList()),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 30,
                              ),
                              Wrap(
                                direction: Axis.horizontal,
                                children: widget.dividas.map((e) {
                                  if (e.faturas
                                          .firstWhere(
                                              (element) =>
                                                  element.ano ==
                                                      state.anoAtual &&
                                                  element.mes ==
                                                      state.mesAtual.id,
                                              orElse: () => FaturaMensalEntity(
                                                    ano: state.anoAtual,
                                                    mes: state.mesAtual.id,
                                                    valor: 0,
                                                    pago: false,
                                                  ))
                                          .valor ==
                                      0) {
                                    return SizedBox.shrink();
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 20,
                                          width: 20,
                                          color: e.cor,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          e.nome,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Screenshot(
                      controller: widget.screenshotDevedoresController,
                      child: Container(
                        color: Colors.black,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (valorTotalDevedores != 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    AppStrings.devedores,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: .7),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final result = await widget
                                          .screenshotDevedoresController
                                          .capture();
                                      if (result != null) {
                                        final directory =
                                            await getApplicationDocumentsDirectory();
                                        final imagePath = await File(
                                                '${directory.path}/image.png')
                                            .create();
                                        await imagePath.writeAsBytes(result);
                                        await Share.shareXFiles(
                                          [
                                            XFile(imagePath.path),
                                          ],
                                          text: AppStrings.baixePayplan,
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      Icons.share,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                valorTotalDevedores.real,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Center(
                                child: SizedBox(
                                  height: 300,
                                  width: 300,
                                  child: PieChart(
                                    PieChartData(
                                      sections: widget.devedores
                                          .asMap()
                                          .entries
                                          .map((e) {
                                        return PieChartSectionData(
                                          radius: 100,
                                          value: e.value.valor,
                                          title: e.value.valor.real,
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          showTitle: true,
                                          color: Colors.primaries[
                                              e.key % Colors.primaries.length],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 30,
                              ),
                              Wrap(
                                direction: Axis.horizontal,
                                children: widget.devedores.map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 20,
                                          width: 20,
                                          color: Colors.primaries[
                                              widget.devedores.indexOf(e) %
                                                  Colors.primaries.length],
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          e.nome,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 130,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
