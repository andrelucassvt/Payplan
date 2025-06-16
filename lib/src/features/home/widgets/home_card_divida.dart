import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/nova_divida/view/nova_divida_view.dart';
import 'package:notes_app/src/util/colors/app_colors.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/service/open_app_admob.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/glass_container_widget.dart';

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
      (timeStamp) {
        _faturaTextController = MoneyMaskedTextController(
          initialValue: valorFatura,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (faturaAtual == null) {
      return SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(
        bottom: 10,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: widget.dividaEntity.cor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 20,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.dividaEntity.nome,
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  '\$${format.format(faturaAtual!.valor)}',
                  maxLines: 2,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    decoration:
                        faturaAtual!.pago ? TextDecoration.lineThrough : null,
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 50,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder(
                valueListenable: UserController.user,
                builder: (context, user, ___) {
                  return Row(
                    children: [
                      InkWell(
                        onTap: () {
                          _editarFaturaBottomSheet(user.isPlus);
                        },
                        child: GlassContainerWidget(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            AppStrings.editarFatura,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      InkWell(
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
                        child: GlassContainerWidget(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Column(
                children: [
                  Text(
                    faturaAtual!.pago ? AppStrings.paga : AppStrings.naoPaga,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Switch(
                    value: faturaAtual!.pago,
                    onChanged: (value) {
                      final tratamentoFaturaListaFatura =
                          widget.dividaEntity.faturas.map(
                        (e) {
                          if (e.ano == faturaAtual!.ano &&
                              e.mes == faturaAtual!.mes) {
                            return faturaAtual!.copyWith(
                              pago: value,
                            );
                          }
                          return e;
                        },
                      ).toList();
                      widget.homeCubit.atualizarDivida(
                        widget.dividaEntity.copyWith(
                          faturas: tratamentoFaturaListaFatura,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }

  void _editarFaturaBottomSheet(bool isPlus) {
    if (!isPlus) {
      AppOpenAdManager.appOpenAd?.show();
    }
    double valorModificado = 0;
    _faturaTextController.updateValue(faturaAtual!.valor);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassContainerWidget(
          margin: MediaQuery.of(context).viewInsets,
          padding: EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 20,
              ),
              Text(
                AppStrings.editarFatura,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
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
                  controller: _faturaTextController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.valorParcela,
                    labelStyle: TextStyle(
                      color: Colors.white,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
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
              ),
              SizedBox(
                height: 50,
              ),
              InkWell(
                onTap: () {
                  final tratamentoFaturaListaFatura =
                      widget.dividaEntity.faturas.map(
                    (e) {
                      if (e.ano == faturaAtual!.ano &&
                          e.mes == faturaAtual!.mes) {
                        return faturaAtual!.copyWith(
                          valor: valorModificado,
                        );
                      }
                      return e;
                    },
                  ).toList();
                  if (tratamentoFaturaListaFatura.isEmpty) {
                    widget.homeCubit.atualizarDivida(
                      widget.dividaEntity.copyWith(
                        faturas: [
                          faturaAtual!.copyWith(
                            valor: valorModificado,
                          ),
                        ],
                      ),
                    );
                  } else {
                    final resultVerificacaoFatura = tratamentoFaturaListaFatura
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
                            faturaAtual!.copyWith(
                              valor: valorModificado,
                            ),
                        ],
                      ),
                    );
                  }

                  Navigator.of(context).pop();
                },
                child: GlassContainerWidget(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Text(
                    AppStrings.salvar,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 50,
              ),
            ],
          ),
        );
      },
    );
  }
}
