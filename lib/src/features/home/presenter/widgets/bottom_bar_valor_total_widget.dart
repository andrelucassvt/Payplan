import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.lightBlueAccent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
        ],
      ),
    );
  }
}
