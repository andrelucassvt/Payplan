import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:localization/localization.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/home/widgets/home_card_divida.dart';
import 'package:notes_app/src/features/home/widgets/home_total_widget.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/service/ads/ad_config.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/admob_banner_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    required this.cubit,
    required this.scrollController,
    super.key,
  });
  final HomeCubit cubit;
  final ScrollController scrollController;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final format = NumberFormat.currency(locale: "pt_BR", symbol: "");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<HomeCubit, HomeState>(
        bloc: widget.cubit,
        listener: (context, state) {
          if (state is HomeVersaoNova) {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
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
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeTotalWidget(
                  cubit: widget.cubit,
                  state: state,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.novaDivida,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: state.dividas.isEmpty
                      ? _EmptyState(cubit: widget.cubit)
                      : ListView.builder(
                          itemCount: state.dividas.length,
                          controller: widget.scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
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
                                          adUnitId: AdConfig.homeBanner1,
                                        ),
                                      if (index == 1)
                                        AdmobBannerWidget(
                                          adUnitId: AdConfig.homeBanner2,
                                        ),
                                    ],
                                  ],
                                );
                              },
                            );
                          },
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cubit});
  final HomeCubit cubit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma dívida cadastrada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toque no + para adicionar sua\nprimeira dívida',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
