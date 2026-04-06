import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:notes_app/src/features/devedores/cubit/devedores_cubit.dart';
import 'package:notes_app/src/features/devedores/view/widgets/card_devedores_widget.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/helpers/devedores_helper.dart';
import 'package:notes_app/src/util/service/ads/ad_config.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/admob_banner_widget.dart';

const _kBackground = Color(0xFFF8F9FF);
const _kAccent = Color(0xFF5C5FEF);
const _kTextPrimary = Color(0xFF1F2937);
const _kTextSecondary = Color(0xFF6B7280);
const _kSurface = Color(0xFFF3F4FF);

class DevedoresView extends StatefulWidget {
  const DevedoresView({
    required this.devedoresCubit,
    required this.scrollController,
    super.key,
  });
  final DevedoresCubit devedoresCubit;
  final ScrollController scrollController;

  @override
  State<DevedoresView> createState() => _DevedoresViewState();
}

class _DevedoresViewState extends State<DevedoresView> {
  final nomeTextController = TextEditingController();
  final pixTextController = TextEditingController();
  final faturaTextController = MoneyMaskedTextController();
  final mensagemTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.devedoresCubit.buscarDevedores();
  }

  void _openNovoDevedorModal([dynamic devedoresEntity]) {
    showNovoDevedorModal(
      context: context,
      cubit: widget.devedoresCubit,
      nomeTextController: nomeTextController,
      pixTextController: pixTextController,
      faturaTextController: faturaTextController,
      mensagemTextController: mensagemTextController,
      devedoresEntity: devedoresEntity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: _kTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: _kTextPrimary),
        title: Text(AppStrings.devedores),
      ),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DevedoresCubit, DevedoresState>(
          bloc: widget.devedoresCubit,
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // — Total card —
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _kAccent.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.total,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _kTextSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.totalValorDevedor.real,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: _kTextPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _openNovoDevedorModal,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          AppStrings.novoDevedor,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // — Section label —
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    AppStrings.devedores.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // — List —
                Expanded(
                  child: state.devedores.isEmpty
                      ? _EmptyState(onAdd: _openNovoDevedorModal)
                      : ListView.builder(
                          controller: widget.scrollController,
                          itemCount: state.devedores.length,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          itemBuilder: (context, index) {
                            return ValueListenableBuilder(
                              valueListenable: UserController.user,
                              builder: (context, user, __) {
                                return Column(
                                  children: [
                                    CardDevedoresWidget(
                                      index: index + 1,
                                      devedoresEntity: state.devedores[index],
                                      devedoresCubit: widget.devedoresCubit,
                                      editarDevedor: () =>
                                          _openNovoDevedorModal(
                                        state.devedores[index],
                                      ),
                                    ),
                                    if (!user.isPlus && index == 0)
                                      AdmobBannerWidget(
                                        adUnitId: AdConfig.devedoresBanner,
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: _kSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 36,
              color: _kAccent,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhum devedor cadastrado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione quem te deve\npara controlar os valores',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _kTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppStrings.novoDevedor),
          ),
        ],
      ),
    );
  }
}
