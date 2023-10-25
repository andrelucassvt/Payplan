import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/src/util/dto/graphic_dto.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

class GraphicView extends StatefulWidget {
  const GraphicView({
    required this.params,
    super.key,
  });
  final GraphicDto params;

  @override
  State<GraphicView> createState() => _GraphicViewState();
}

class _GraphicViewState extends State<GraphicView> {
  Map<String, double> dataMap = {};
  List<CartaoEntity> cartoes = [];

  @override
  void initState() {
    super.initState();
    initMap();
  }

  void initMap() {
    cartoes = widget.params.cartoes;
    cartoes.removeWhere((element) =>
        element.isMensal == false &&
        element.mes != widget.params.mesSelecionado.getMonthNumber());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.graficoGastos),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: 300,
                width: 300,
                child: PieChart(
                  PieChartData(
                      sections: cartoes.map((e) {
                    return PieChartSectionData(
                      radius: 60,
                      value: e.dividas.isEmpty
                          ? 0
                          : double.tryParse(
                              e.dividas
                                  .firstWhere(
                                      orElse: () => FaturaEntity(
                                            idCartao: '',
                                            ano: '',
                                            mes: '',
                                            valorFatura: '0',
                                          ),
                                      (element) =>
                                          element.mes ==
                                          widget.params.mesSelecionado)
                                  .valorFatura,
                            ),
                      title: e.nome,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                      ),
                      showTitle: true,
                      color: Color(e.cor),
                    );
                  }).toList()),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      AppStrings.voltar,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
