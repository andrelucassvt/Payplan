import 'package:flutter/material.dart';
import 'package:notes_app/src/util/dto/graphic_dto.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:pie_chart/pie_chart.dart';

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

  @override
  void initState() {
    super.initState();
    initMap();
  }

  void initMap() {
    final cartoes = widget.params.cartoes;
    cartoes.removeWhere((element) =>
        element.isMensal == false &&
        element.mes != widget.params.mesSelecionado.getMonthNumber());
    final result = cartoes.map((e) {
      return e.dividas
          .where((element) => element.mes == widget.params.mesSelecionado)
          .toList();
    }).toList();

    final Map<String, double> map = {
      for (var i = 0; i < cartoes.length; i++)
        cartoes[i].nome:
            result[i].isNotEmpty ? double.parse(result[i][0].valorFatura) : 0.0,
    };
    setState(() {
      dataMap = map;
    });
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 50,
            ),
            PieChart(
              dataMap: dataMap,
              animationDuration: const Duration(milliseconds: 800),
              chartRadius: MediaQuery.of(context).size.width / 1.2,
              initialAngleInDegree: 0,
              ringStrokeWidth: 32,
              chartValuesOptions: const ChartValuesOptions(
                showChartValuesInPercentage: true,
              ),
              legendOptions: const LegendOptions(
                showLegendsInRow: true,
                legendPosition: LegendPosition.bottom,
                showLegends: true,
                legendTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 60,
                margin: const EdgeInsets.symmetric(
                  horizontal: 30,
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
            const SizedBox(
              height: 15,
            )
          ],
        ),
      ),
    );
  }
}
