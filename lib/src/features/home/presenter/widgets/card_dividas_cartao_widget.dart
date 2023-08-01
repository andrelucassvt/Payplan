import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/app_dialog.dart';

class CardDividasCartaoWidget extends StatefulWidget {
  const CardDividasCartaoWidget({
    required this.cartao,
    required this.valorFaturaCartao,
    required this.showAdicionarAtualizarValorFatura,
    required this.deletarCartao,
    required this.atualizarCartao,
    required this.mudarInformacaoCartao,
    required this.mesSelecionado,
    super.key,
  });
  final CartaoEntity cartao;
  final List<FaturaEntity> valorFaturaCartao;
  final VoidCallback showAdicionarAtualizarValorFatura;
  final VoidCallback deletarCartao;
  final VoidCallback atualizarCartao;
  final Function(CartaoEntity cartaoEntity) mudarInformacaoCartao;
  final String mesSelecionado;

  @override
  State<CardDividasCartaoWidget> createState() =>
      _CardDividasCartaoWidgetState();
}

class _CardDividasCartaoWidgetState extends State<CardDividasCartaoWidget> {
  String isDividaTitulo() {
    if (widget.cartao.isDivida) {
      return '${widget.cartao.nome} ${AppStrings.dividaExterna}';
    }
    return widget.cartao.nome;
  }

  NumberFormat formatador =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  FaturaEntity get _faturaAtual => widget.valorFaturaCartao.first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        child: Row(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Color(
                  widget.cartao.cor,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(
              width: 20,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isDividaTitulo(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.valorFaturaCartao.isNotEmpty)
                    Text(
                      formatador.format(double.parse(_faturaAtual.valorFatura)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.valorFaturaCartao.first.isPago
                            ? Colors.blue
                            : Colors.red,
                        fontSize: 20,
                      ),
                    ),
                  if (widget.valorFaturaCartao.isEmpty) ...[
                    ElevatedButton(
                      onPressed: widget.showAdicionarAtualizarValorFatura,
                      child: Text(
                        AppStrings.addValor,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.valorFaturaCartao.isNotEmpty)
              FlutterSwitch(
                valueFontSize: 10.0,
                width: 100,
                borderRadius: 30.0,
                value: _faturaAtual.isPago,
                showOnOff: true,
                activeText: AppStrings.paga,
                inactiveText: AppStrings.naoPaga,
                onToggle: (val) {
                  final dividasAtualizadas =
                      List<FaturaEntity>.from(widget.cartao.dividas)
                        ..removeWhere(
                            (divida) => divida.mes == widget.mesSelecionado)
                        ..add(_faturaAtual.copyWith(
                          isPago: val,
                        ));
                  widget.mudarInformacaoCartao(
                      widget.cartao.copyWith(dividas: dividasAtualizadas));
                },
              ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    onTap: widget.showAdicionarAtualizarValorFatura,
                    child: Text(
                      AppStrings.editarFatura,
                    ),
                  ),
                  PopupMenuItem(
                    onTap: widget.atualizarCartao,
                    child: Text(
                      widget.cartao.isDivida
                          ? AppStrings.editarDivida
                          : AppStrings.editarCartao,
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () async {
                      Future.delayed(const Duration(seconds: 0), () {
                        AppDialog().showDialogApp(
                          title: AppStrings.atencao,
                          subTitle: AppStrings.esseCartaoSeraRemovido,
                          textoButton1: AppStrings.deletar,
                          corTextoOnTap: Colors.red,
                          onTapButton1: widget.deletarCartao,
                        );
                      });
                    },
                    child: Text(
                      AppStrings.deletar,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  String formatNumber(String value, int decimalPlaces) {
    const separator = ",";
    const decimalSeparator = ".";
    final length = value.length;

    if (length <= decimalPlaces) {
      return "0$decimalSeparator${value.padLeft(decimalPlaces, '0')}";
    }

    final decimalIndex = length - decimalPlaces;
    final wholePart = value.substring(0, decimalIndex);
    final decimalPart = value.substring(decimalIndex);

    final formattedWholePart = wholePart.replaceAllMapped(
      RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
      (Match match) => "${match.group(1)}$separator",
    );

    return "$formattedWholePart$decimalSeparator$decimalPart";
  }
}
