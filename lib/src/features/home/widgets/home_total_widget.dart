import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/src/features/devedores/view/devedores_view.dart';
import 'package:notes_app/src/features/grafico/view/grafico_view.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/nova_divida/view/nova_divida_view.dart';
import 'package:notes_app/src/util/colors/app_colors.dart';
import 'package:notes_app/src/util/enum/meses_enum.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

class HomeTotalWidget extends StatefulWidget {
  const HomeTotalWidget({
    required this.cubit,
    required this.state,
    super.key,
  });
  final HomeCubit cubit;
  final HomeState state;

  @override
  State<HomeTotalWidget> createState() => _HomeTotalWidgetState();
}

class _HomeTotalWidgetState extends State<HomeTotalWidget> {
  final format = NumberFormat.currency(locale: "pt_BR", symbol: "");

  HomeCubit get _cubit => widget.cubit;
  HomeState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurpleAccent.shade200,
            Colors.deepPurple.shade800
          ],
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () async {
                  final scrollController = FixedExtentScrollController(
                    initialItem: state.anoAtual - 2024,
                  );

                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) {
                      return Container(
                        height: 216,
                        padding: const EdgeInsets.only(top: 6.0),
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        color: Colors.black,
                        child: CupertinoPicker(
                          itemExtent: 50,
                          scrollController: scrollController,
                          onSelectedItemChanged: (index) {
                            _cubit.mudarAnoAtual(
                              2024 + index,
                            );
                          },
                          children: List.generate(
                            100,
                            (index) {
                              return Center(
                                child: Text(
                                  (2024 + index).toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Row(
                  children: [
                    Text(
                      state.anoAtual.toString(),
                      style: TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.touch_app,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  PopupMenuButton<MesesEnum>(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.whiteOpacity,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            state.mesAtual.nome,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) {
                      return MesesEnum.values.map(
                        (e) {
                          return PopupMenuItem<MesesEnum>(
                            value: e,
                            child: Text(e.nome),
                            onTap: () {
                              _cubit.mudarMesAtual(e);
                            },
                          );
                        },
                      ).toList();
                    },
                  ),
                ],
              ),
            ],
          ),
          Divider(),
          const SizedBox(
            height: 10,
          ),
          Text(
            AppStrings.total,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w300,
            ),
          ),
          Text(
            state.totalGastos.real,
            maxLines: 2,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Expanded(
                child: buttonContainerBase(
                  text: AppStrings.novaDivida,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NovaDividaView(
                          homeCubit: _cubit,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 7,
              ),
              Expanded(
                child: buttonContainerBase(
                  text: '-${AppStrings.desconto}',
                  onTap: () {
                    showModalDesconto(state.totalGastos);
                  },
                ),
              ),
              const SizedBox(
                width: 7,
              ),
              PopupMenuButton<String>(
                child: buttonContainerBase(
                  text: '***',
                  icon: Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                  ),
                  width: 60,
                  onTap: null,
                ),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 'Devedores',
                      child: Text(AppStrings.devedores),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DevedoresView(),
                          ),
                        );
                      },
                    ),
                    if (state.totalGastos != 0)
                      PopupMenuItem(
                        value: 'Grafico',
                        child: Text(AppStrings.graficoGastos),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GraficoView(
                                homeCubit: _cubit,
                                dividas: state.dividas,
                              ),
                            ),
                          );
                        },
                      ),
                  ];
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buttonContainerBase({
    required String text,
    VoidCallback? onTap,
    double? width,
    Widget? icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.whiteOpacity,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: icon ??
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
      ),
    );
  }

  void showModalDesconto(double valorDesseMes) {
    final faturaTextController = MoneyMaskedTextController(initialValue: 0.00);
    double valorDigitado = 0.0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: Colors.white,
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(40.0),
              topRight: const Radius.circular(40.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 20,
                  bottom: 10,
                ),
                child: Text(
                  AppStrings.adicioneOValorTotalDescontado,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Divider(),
              Text(
                AppStrings.valorDesseMes,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                valorDesseMes.real,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                AppStrings.digiteOSaldoQueSeraDescontado,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.whiteOpacity,
                        ),
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                      child: TextFormField(
                        controller: faturaTextController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                            labelText: AppStrings.salario,
                            labelStyle: TextStyle(
                              color: Colors.white,
                            )),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final filtro1 = value.replaceAll('.', '');
                            valorDigitado =
                                double.parse(filtro1.replaceAll(',', '.'));

                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final resultado = valorDigitado - valorDesseMes;
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(AppStrings.saldoRestante),
                          content: Text(
                            resultado.real,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Icon(Icons.check),
                  ),
                ],
              ),
              const SizedBox(
                height: 50,
              ),
            ],
          ),
        );
      },
    );
  }
}
