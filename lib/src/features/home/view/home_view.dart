import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:localization/localization.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/home/widgets/home_card_divida.dart';
import 'package:notes_app/src/features/home/widgets/home_total_widget.dart';
import 'package:notes_app/src/features/nova_divida/view/nova_divida_view.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/admob_banner_widget.dart';
import 'package:notes_app/src/util/widgets/glass_container_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    required this.cubit,
  });
  final HomeCubit cubit;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final format = NumberFormat.currency(locale: "pt_BR", symbol: "");
  final _scrollViewController = ScrollController();
  final bool _isSafeAreaBottom = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<HomeCubit, HomeState>(
        bloc: widget.cubit,
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
                  cubit: widget.cubit,
                  state: state,
                ),
                const SizedBox(
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
                      color: Colors.grey.withValues(alpha: .3),
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
                                        homeCubit: widget.cubit,
                                      ),
                                    ),
                                  );
                                },
                                child: GlassContainerWidget(
                                  height: 50,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
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
                              padding: EdgeInsets.only(
                                bottom: 150,
                              ),
                              itemBuilder: (context, index) {
                                return ValueListenableBuilder(
                                  valueListenable: UserController.user,
                                  builder: (context, user, __) {
                                    return Column(
                                      children: [
                                        HomeCardDivida(
                                          dividaEntity: state.dividas[index],
                                          homeCubit: widget.cubit,
                                        ),
                                        if (!user.isPlus) ...[
                                          if (index == 0)
                                            AdmobBannerWidget(
                                              bannerId: Platform.isAndroid
                                                  ? 'ca-app-pub-3652623512305285/7988227382'
                                                  : 'ca-app-pub-3652623512305285/8865877557',
                                            ),
                                          if (index == 1)
                                            AdmobBannerWidget(
                                              bannerId: Platform.isAndroid
                                                  ? 'ca-app-pub-3652623512305285/5263156340'
                                                  : 'ca-app-pub-3652623512305285/1323911334',
                                            ),
                                        ],
                                      ],
                                    );
                                  },
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
