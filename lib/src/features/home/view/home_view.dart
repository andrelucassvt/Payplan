import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/home/widgets/home_card_divida.dart';
import 'package:notes_app/src/features/home/widgets/home_total_widget.dart';
import 'package:notes_app/src/features/nova_divida/view/nova_divida_view.dart';
import 'package:notes_app/src/util/colors/app_colors.dart';
import 'package:notes_app/src/util/service/notification_service.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/admob_native_banner.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _cubit = HomeCubit();
  final format = NumberFormat.currency(locale: "pt_BR", symbol: "");
  final _scrollViewController = ScrollController();
  final bool _isSafeAreaBottom = false;

  @override
  void initState() {
    super.initState();
    _cubit.buscarDividas();
    _verificarPermissaoNotificacao();
  }

  Future<void> _verificarPermissaoNotificacao() async {
    final result = await NotificationService().verificarPermissaoNotificacao();
    if (result) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.blue,
            content: InkWell(
              onTap: () {
                openAppSettings();
              },
              child: Center(
                child: Text(
                  AppStrings.permitirNotificacoes,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      NotificationService().showLocalNotification(
        id: 0,
        title: AppStrings.atencao,
        body: AppStrings.naoPercaADataPagamento,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<HomeCubit, HomeState>(
        bloc: _cubit,
        builder: (context, state) {
          return SafeArea(
            bottom: _isSafeAreaBottom,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  HomeTotalWidget(
                    cubit: _cubit,
                    state: state,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(
                        left: 10,
                        right: 10,
                        top: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(.3),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                      ),
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
                              )
                            : ListView.builder(
                                itemCount: state.dividas.length,
                                controller: _scrollViewController,
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: [
                                      HomeCardDivida(
                                        dividaEntity: state.dividas[index],
                                        homeCubit: _cubit,
                                      ),
                                      if (index == 0) ...[
                                        AdmobNativeBanner(
                                          bannerId: Platform.isAndroid
                                              ? 'ca-app-pub-3652623512305285/8596201581'
                                              : 'ca-app-pub-3652623512305285/8683831496',
                                          textColor: Platform.isAndroid
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ],
                                      if (index == 2) ...[
                                        AdmobNativeBanner(
                                          mainBackgroundColor: Colors.red,
                                          bannerId: Platform.isAndroid
                                              ? 'ca-app-pub-3652623512305285/2065348602'
                                              : 'ca-app-pub-3652623512305285/4665497764',
                                          textColor: Platform.isAndroid
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
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
