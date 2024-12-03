import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/home/widgets/home_card_divida.dart';
import 'package:notes_app/src/features/nova_divida/view/nova_divida_view.dart';
import 'package:notes_app/src/util/colors/app_colors.dart';
import 'package:notes_app/src/util/enum/meses_enum.dart';
import 'package:notes_app/src/util/service/notification_service.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/app_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _cubit = HomeCubit();
  bool mostrarIconePermitirNotificacao = false;
  double interpolacao = 0.0;
  final format = NumberFormat.currency(locale: "pt_BR", symbol: "");

  @override
  void initState() {
    super.initState();
    _cubit.buscarDividas();
  }

  Future<void> verificarPermissaoNotificacao() async {
    final result = await NotificationService().verificarPermissaoNotificacao();
    setState(() {
      if (result) {
        mostrarIconePermitirNotificacao = true;
      } else {
        mostrarIconePermitirNotificacao = false;
      }
    });
  }

  Widget _permitirNotificao() {
    return InkWell(
      onTap: () {
        AppDialog().showDialogApp(
          contextCustom: context,
          barrierDismissible: false,
          title: AppStrings.atencao,
          subTitle: AppStrings.paraPermitirQueOPayplan,
          onTapButton1: () async {
            await verificarPermissaoNotificacao();
            if (!mostrarIconePermitirNotificacao) {
              Navigator.of(context).pop();
            } else {
              openAppSettings();
            }
          },
          onTapButton2: () async {
            Navigator.of(context).pop();
          },
          textoButton1: AppStrings.abrirConfiguracoes,
        );
      },
      child: CircleAvatar(
        backgroundColor: AppColors.whiteOpacity,
        child: const Icon(
          Icons.notification_important,
          color: Colors.yellow,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<HomeCubit, HomeState>(
        bloc: _cubit,
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Container(
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
                            PopupMenuButton<int>(
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
                              itemBuilder: (context) {
                                return List.generate(
                                  100,
                                  (index) {
                                    int anoBase = 2024;
                                    if (index == 0) {
                                      return PopupMenuItem<int>(
                                        value: 2024,
                                        child: Text(
                                          2024.toString(),
                                        ),
                                        onTap: () {
                                          _cubit.mudarAnoAtual(
                                            anoBase,
                                          );
                                        },
                                      );
                                    }
                                    return PopupMenuItem<int>(
                                      value: anoBase + index,
                                      child: Text(
                                        (anoBase + index).toString(),
                                      ),
                                      onTap: () {
                                        _cubit.mudarAnoAtual(
                                          anoBase + index,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                            Row(
                              children: [
                                if (mostrarIconePermitirNotificacao)
                                  _permitirNotificao(),
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
                          '\$${format.format(state.totalGastos)}',
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
                              child: InkWell(
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
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteOpacity,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppStrings.novaDivida,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    showModalDesconto(state.totalGastos),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteOpacity,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '-${AppStrings.desconto}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            InkWell(
                              onTap: () {},
                              child: CircleAvatar(
                                backgroundColor: AppColors.whiteOpacity,
                                child: Icon(
                                  Icons.donut_large,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: 20,
                      ),
                      padding: EdgeInsets.only(
                        left: 10,
                        right: 10,
                        top: 10,
                        bottom: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(.3),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 2,
                            ),
                            child: Text(
                              AppStrings.minhasDividas,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                12.0,
                              ),
                              child: state.dividas.isEmpty
                                  ? Center(
                                      child: InkWell(
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
                                        child: Container(
                                          height: 50,
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 50,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.whiteOpacity,
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          child: Center(
                                            child: Text(
                                              AppStrings.novaDivida,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: state.dividas.length,
                                      itemBuilder: (context, index) {
                                        return HomeCardDivida(
                                          dividaEntity: state.dividas[index],
                                          homeCubit: _cubit,
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
                '\$${format.format(valorDesseMes)}',
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
                            labelText: AppStrings.valorParcela,
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
                            '\$${format.format(resultado)}',
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
