import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/nova_divida/view/nova_divida_view.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/service/ads/app_open_ad_service.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

const _kTextPrimary = Color(0xFF1F2937);
const _kTextSecondary = Color(0xFF6B7280);
const _kSurface = Color(0xFFF3F4FF);
const _kAccent = Color(0xFF5C5FEF);

class HomeCardDivida extends StatefulWidget {
  const HomeCardDivida({
    required this.dividaEntity,
    required this.homeCubit,
    super.key,
  });
  final DividaEntity dividaEntity;
  final HomeCubit homeCubit;

  @override
  State<HomeCardDivida> createState() => _HomeCardDividaState();
}

class _HomeCardDividaState extends State<HomeCardDivida> {
  final format = NumberFormat.currency(locale: "pt_BR", symbol: "");
  HomeState get homeState => widget.homeCubit.state;

  double valorFatura = 0.0;
  late final MoneyMaskedTextController _faturaTextController;

  FaturaMensalEntity? get faturaAtual {
    final result = widget.dividaEntity.faturas
        .where(
          (element) =>
              element.ano == widget.homeCubit.state.anoAtual &&
              element.mes == widget.homeCubit.state.mesAtual.id,
        )
        .toList();

    if (result.isEmpty && !widget.dividaEntity.mensal) {
      return null;
    }
    if (widget.dividaEntity.faturas.isEmpty || result.isEmpty) {
      return FaturaMensalEntity(
        ano: widget.homeCubit.state.anoAtual,
        mes: widget.homeCubit.state.mesAtual.id,
        pago: false,
        valor: 0,
      );
    }

    valorFatura = result[0].valor;
    setState(() {});

    return result[0];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _faturaTextController = MoneyMaskedTextController(
          initialValue: valorFatura,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (faturaAtual == null) return const SizedBox.shrink();

    final cor = widget.dividaEntity.cor;
    final isPaid = faturaAtual!.pago;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: cor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.dividaEntity.nome,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPaid ? AppStrings.paga : AppStrings.naoPaga,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isPaid
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${format.format(faturaAtual!.valor)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextPrimary,
                                  decoration: isPaid
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: _kTextSecondary,
                                ),
                              ),
                              Transform.scale(
                                alignment: Alignment.centerRight,
                                scale: 0.85,
                                child: Switch(
                                  value: isPaid,
                                  activeColor: const Color(0xFF10B981),
                                  onChanged: (value) {
                                    final updated =
                                        widget.dividaEntity.faturas.map(
                                      (e) {
                                        if (e.ano == faturaAtual!.ano &&
                                            e.mes == faturaAtual!.mes) {
                                          return faturaAtual!
                                              .copyWith(pago: value);
                                        }
                                        return e;
                                      },
                                    ).toList();
                                    widget.homeCubit.atualizarDivida(
                                      widget.dividaEntity
                                          .copyWith(faturas: updated),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ValueListenableBuilder(
                            valueListenable: UserController.user,
                            builder: (context, user, ___) {
                              return Row(
                                children: [
                                  _ActionChip(
                                    label: AppStrings.editarFatura,
                                    onTap: () => _editarFaturaBottomSheet(
                                      user.isPlus,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _ActionChip(
                                    icon: Icons.edit_outlined,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => NovaDividaView(
                                            homeCubit: widget.homeCubit,
                                            dividaEntity: widget.dividaEntity,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editarFaturaBottomSheet(bool isPlus) {
    if (!isPlus) {
      AppOpenAdService.instance.show();
    }
    double valorModificado = 0;
    _faturaTextController.updateValue(faturaAtual!.valor);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.editarFatura,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _faturaTextController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.valorParcela,
                    labelStyle: const TextStyle(color: _kTextSecondary),
                    filled: true,
                    fillColor: _kSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kAccent, width: 1.5),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final filtro1 = value.replaceAll('.', '');
                      valorModificado =
                          double.parse(filtro1.replaceAll(',', '.'));
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _kAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final tratamentoFaturaListaFatura =
                          widget.dividaEntity.faturas.map(
                        (e) {
                          if (e.ano == faturaAtual!.ano &&
                              e.mes == faturaAtual!.mes) {
                            return faturaAtual!
                                .copyWith(valor: valorModificado);
                          }
                          return e;
                        },
                      ).toList();
                      if (tratamentoFaturaListaFatura.isEmpty) {
                        widget.homeCubit.atualizarDivida(
                          widget.dividaEntity.copyWith(
                            faturas: [
                              faturaAtual!.copyWith(valor: valorModificado),
                            ],
                          ),
                        );
                      } else {
                        final resultVerificacaoFatura =
                            tratamentoFaturaListaFatura
                                .where(
                                  (e) =>
                                      e.ano == faturaAtual!.ano &&
                                      e.mes == faturaAtual!.mes,
                                )
                                .toList();
                        widget.homeCubit.atualizarDivida(
                          widget.dividaEntity.copyWith(
                            faturas: [
                              ...tratamentoFaturaListaFatura,
                              if (resultVerificacaoFatura.isEmpty)
                                faturaAtual!.copyWith(valor: valorModificado),
                            ],
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      AppStrings.salvar,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({this.label, this.icon, required this.onTap});
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: icon != null
            ? Icon(icon, size: 16, color: _kAccent)
            : Text(
                label!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kAccent,
                ),
              ),
      ),
    );
  }
}
