import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

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

  FaturaMensalEntity? get faturaAtual {
    final result = widget.dividaEntity.faturas
        .where(
          (element) =>
              element.ano == widget.homeCubit.state.anoAtual &&
              element.mes == widget.homeCubit.state.mesAtual.id,
        )
        .toList();

    if (result.isEmpty) {
      return null;
    }

    if (widget.dividaEntity.faturas.isEmpty) {
      return FaturaMensalEntity(
        ano: widget.homeCubit.state.anoAtual,
        mes: widget.homeCubit.state.mesAtual.id,
        pago: false,
        valor: 0,
      );
    }

    return result[0];
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
            height: 40,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppStrings.editarFatura,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    faturaAtual!.pago ? AppStrings.paga : AppStrings.naoPaga,
                    style: TextStyle(
                      color: Colors.white,
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
}
