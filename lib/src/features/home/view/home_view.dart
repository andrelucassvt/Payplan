import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  bool _isCollapsed = false;

  /// Altura do cabeçalho expandido. A lista ocupa a tela inteira e reserva
  /// esse espaço no topo, para que encolher o cabeçalho não altere a altura
  /// da área de scroll (o que fazia o scroll "pular" e reexpandir).
  double _alturaCabecalho = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController.offset;
    if (!_isCollapsed && offset > 60) {
      setState(() => _isCollapsed = true);
    } else if (_isCollapsed && offset < 20) {
      setState(() => _isCollapsed = false);
    }
  }

  void _onAlturaCabecalhoChanged(double altura) {
    if (altura != _alturaCabecalho) {
      setState(() => _alturaCabecalho = altura);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
            bottom: false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: state.dividas.isEmpty
                      ? Padding(
                          padding: EdgeInsets.only(top: _alturaCabecalho),
                          child: _EmptyState(cubit: widget.cubit),
                        )
                      : ListView.builder(
                          itemCount: state.dividas.length + 1,
                          controller: widget.scrollController,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            _alturaCabecalho,
                            16,
                            120,
                          ),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                                child: Text(
                                  AppStrings.dividas,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }
                            final i = index - 1;
                            return ValueListenableBuilder(
                              valueListenable: UserController.user,
                              builder: (context, user, __) {
                                return Column(
                                  children: [
                                    HomeCardDivida(
                                      dividaEntity: state.dividas[i],
                                      homeCubit: widget.cubit,
                                    ),
                                    if (!user.isPlus) ...[
                                      if (i == 0)
                                        AdmobBannerWidget(
                                          adUnitId: AdConfig.homeBanner1,
                                        ),
                                      if (i == 1)
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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ColoredBox(
                    color: theme.scaffoldBackgroundColor,
                    child: HomeTotalWidget(
                      cubit: widget.cubit,
                      state: state,
                      isCollapsed: _isCollapsed,
                      onAlturaExpandidaChanged: _onAlturaCabecalhoChanged,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cubit});
  final HomeCubit cubit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(AppStrings.nenhumaDivida, style: tt.titleMedium),
            const SizedBox(height: 4),
            Text(
              AppStrings.adicioneUmaDivida,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
