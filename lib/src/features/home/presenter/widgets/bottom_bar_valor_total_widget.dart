import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:pattern_formatter/pattern_formatter.dart';

class BottomBarValorTotalWidget extends StatefulWidget {
  const BottomBarValorTotalWidget({
    required this.valorFaturaCartao,
    super.key,
  });
  final double valorFaturaCartao;

  @override
  State<BottomBarValorTotalWidget> createState() =>
      _BottomBarValorTotalWidgetState();
}

class _BottomBarValorTotalWidgetState extends State<BottomBarValorTotalWidget> {
  NumberFormat formatador =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  NumberFormat formatadorCalculo = NumberFormat.currency(locale: 'pt_BR');

  final _focusNodeEditarFatura = FocusNode();
  final TextEditingController _textControllerEditarFatura =
      TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      decoration: const BoxDecoration(
        color: Colors.lightBlueAccent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(
            AppStrings.total,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(
            width: 15,
          ),
          Text(
            formatador.format(widget.valorFaturaCartao),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return Padding(
                    padding: MediaQuery.of(context).viewInsets,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 20,
                            ),
                            child: Text(
                              'Adicione o valor total que será descontado',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Text(
                            'Valor desse mês:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Text(
                            formatador.format(widget.valorFaturaCartao),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            'Digite o saldo em que será descontado o valor desse mês:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _textControllerEditarFatura,
                                  focusNode: _focusNodeEditarFatura,
                                  onChanged: (value) {
                                    setState(() {
                                      _textControllerEditarFatura.text = value;
                                      _textControllerEditarFatura.selection =
                                          TextSelection.fromPosition(
                                        TextPosition(
                                            offset: _textControllerEditarFatura
                                                .text.length),
                                      );
                                    });
                                  },
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    ThousandsFormatter(allowFraction: true)
                                  ],
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        10.0,
                                      ),
                                    ),
                                    hintText: AppStrings.digiteOValorDoSaldo,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _focusNodeEditarFatura.unfocus();
                                  final result = containsOnlyDotsAndCommas(
                                      _textControllerEditarFatura.text);
                                  if (_textControllerEditarFatura
                                          .text.isNotEmpty &&
                                      !result) {
                                    final valorSaldo = double.parse(
                                        _textControllerEditarFatura.text
                                            .replaceAll(',', ''));
                                    final resultadoSubtracao =
                                        valorSaldo - widget.valorFaturaCartao;

                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Saldo restante'),
                                        content: Text(
                                          'R\$ ${resultadoSubtracao < 0 ? (resultadoSubtracao * -1).toStringAsFixed(2) : resultadoSubtracao.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Icon(Icons.check),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 60,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.calculate_rounded),
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  bool containsOnlyDotsAndCommas(String input) {
    final regex = RegExp(r'^[.,]+$');
    return regex.hasMatch(input);
  }
}
