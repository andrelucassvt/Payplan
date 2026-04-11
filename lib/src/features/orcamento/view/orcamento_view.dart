import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/src/features/orcamento/cubit/orcamento_cubit.dart';
import 'package:notes_app/src/features/orcamento/widgets/orcamento_card_widget.dart';
import 'package:notes_app/src/features/orcamento/widgets/orcamento_total_widget.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/service/ads/ad_config.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/admob_banner_widget.dart';

class OrcamentoView extends StatefulWidget {
  const OrcamentoView({
    required this.cubit,
    required this.scrollController,
    super.key,
  });

  final OrcamentoCubit cubit;
  final ScrollController scrollController;

  @override
  State<OrcamentoView> createState() => _OrcamentoViewState();
}

class _OrcamentoViewState extends State<OrcamentoView> {
  bool _isCollapsed = false;

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
    final shouldCollapse = widget.scrollController.offset > 60;
    if (shouldCollapse != _isCollapsed) {
      setState(() => _isCollapsed = shouldCollapse);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<OrcamentoCubit, OrcamentoState>(
        bloc: widget.cubit,
        builder: (context, state) {
          return SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrcamentoTotalWidget(
                  cubit: widget.cubit,
                  state: state,
                  isCollapsed: _isCollapsed,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.novoOrcamento,
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
                  child: state.orcamentos.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          itemCount: state.orcamentos.length,
                          controller: widget.scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          itemBuilder: (context, index) {
                            return ValueListenableBuilder(
                              valueListenable: UserController.user,
                              builder: (context, user, __) {
                                return Column(
                                  children: [
                                    OrcamentoCardWidget(
                                      orcamento: state.orcamentos[index],
                                      orcamentoCubit: widget.cubit,
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
  const _EmptyState();

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
              Icons.account_balance_wallet_outlined,
              size: 36,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.nenhumOrcamento,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.adicioneUmOrcamento,
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
