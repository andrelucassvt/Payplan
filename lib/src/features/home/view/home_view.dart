import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        NotificationService().showLocalNotification(
          title: AppStrings.atencao,
          body: AppStrings.naoPercaADataPagamento,
        );
      });
    });
    verificarPermissaoNotificacao();
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
                                  15,
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
                                  InkWell(
                                    onTap: () {
                                      AppDialog().showDialogApp(
                                        contextCustom: context,
                                        barrierDismissible: false,
                                        title: AppStrings.atencao,
                                        subTitle:
                                            AppStrings.paraPermitirQueOPayplan,
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
                                        textoButton1:
                                            AppStrings.abrirConfiguracoes,
                                      );
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: AppColors.whiteOpacity,
                                      child: const Icon(
                                        Icons.notification_important,
                                        color: Colors.yellow,
                                      ),
                                    ),
                                  ),
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
                          '\$ 10,200.00',
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
                                onTap: () {},
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
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
                          Text(
                            AppStrings.minhasDividas,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Expanded(
                            child: AnimatedList(
                              controller: _scrollController,
                              initialItemCount: 8,
                              itemBuilder: (context, index, animation) {
                                return AnimatedBuilder(
                                    animation: _scrollController,
                                    builder: (context, child) {
                                      double scale = 1.0;
                                      if (_scrollController.hasClients) {
                                        double offset =
                                            _scrollController.offset / 100;
                                        scale = (1.0 - (offset - index * 0.9))
                                            .clamp(.9, 1);
                                      }
                                      return Transform.scale(
                                        scale: scale,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 20,
                                          ),
                                          child: HomeCardDivida(),
                                        ),
                                      );
                                    });
                              },
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
}
