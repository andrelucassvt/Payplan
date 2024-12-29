import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

class GraficoView extends StatefulWidget {
  const GraficoView({
    required this.dividas,
    required this.homeCubit,
    super.key,
  });
  final List<DividaEntity> dividas;
  final HomeCubit homeCubit;

  @override
  State<GraficoView> createState() => _GraficoViewState();
}

class _GraficoViewState extends State<GraficoView> {
  int touchedIndex = -1;
  HomeState get state => widget.homeCubit.state;

  final adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3652623512305285/2612926407'
      : 'ca-app-pub-3652623512305285/3055208717';

  /// Loads an interstitial ad.
  void loadAd() {
    InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
                // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {},
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                },
                onAdClicked: (ad) {});

            debugPrint('$ad loaded.');
            Future.delayed(const Duration(seconds: 5), () {
              ad.show();
            });
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }

  @override
  void initState() {
    super.initState();
    loadAd();
  }

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
      bottomNavigationBar: SafeArea(
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
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                height: 300,
                width: 300,
                child: PieChart(
                  PieChartData(
                      sections: widget.dividas.map((e) {
                    return PieChartSectionData(
                      radius: 80,
                      value: (e.faturas
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
                          .valor),
                      title: e.nome,
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
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(4, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.green,
            value: 40,
            title: '40%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.green,
              shadows: shadows,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Colors.green,
            value: 30,
            title: '30%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.green,
              shadows: shadows,
            ),
          );
        case 2:
          return PieChartSectionData(
            color: Colors.green,
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.green,
              shadows: shadows,
            ),
          );
        case 3:
          return PieChartSectionData(
            color: Colors.green,
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.red,
              shadows: shadows,
            ),
          );
        default:
          throw Error();
      }
    });
  }
}
