import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:localization/localization.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/home/widgets/home_card_divida.dart';
import 'package:notes_app/src/features/home/widgets/home_total_widget.dart';
import 'package:notes_app/src/features/nova_divida/view/nova_divida_view.dart';
import 'package:notes_app/src/util/colors/app_colors.dart';
import 'package:notes_app/src/util/service/notification_service.dart';
import 'package:notes_app/src/util/service/open_app_admob.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
    _cubit.verificarVersao();
    _verificarPermissaoNotificacao();
    Future.delayed(Duration(seconds: 7), () {
      AppOpenAdManager().loadAd();
    });
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<HomeCubit, HomeState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state is HomeVersaoNova) {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(AppStrings.atencao),
                  content: Text('novaVersaoDisp'.i18n()),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await launchUrlString(
                          Platform.isAndroid
                              ? 'https://play.google.com/store/apps/details?id=com.andre.notes_app'
                              : 'https://apps.apple.com/br/app/payplan/id6450763738',
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text('atualizar'.i18n()),
                    ),
                  ],
                );
              },
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            bottom: _isSafeAreaBottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
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
                                    // if (index == 0) ...[
                                    //   AdmobAdaptiveBanner(
                                    //     bannerId: Platform.isAndroid
                                    //         ? 'ca-app-pub-3652623512305285/5889977427'
                                    //         : 'ca-app-pub-3652623512305285/9198667043',
                                    //   ),
                                    // ],
                                    // if (index == 2) ...[
                                    //   AdmobAdaptiveBanner(
                                    //     bannerId: Platform.isAndroid
                                    //         ? 'ca-app-pub-3652623512305285/7988227382'
                                    //         : 'ca-app-pub-3652623512305285/8865877557',
                                    //   ),
                                    // ],
                                  ],
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
