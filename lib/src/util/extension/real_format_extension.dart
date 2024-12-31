import 'package:intl/intl.dart';

extension RealFormatExtension on double {
  String get real {
    final format = NumberFormat.currency(locale: "pt_BR", symbol: "");
    return '\$${format.format(this)}';
  }
}
