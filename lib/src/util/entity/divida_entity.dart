import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class DividaEntity {
  const DividaEntity({
    required this.id,
    required this.nome,
    required this.mensal,
    required this.cor,
    required this.faturas,
  });

  final String id;
  final String nome;
  final bool mensal;
  final Color cor;
  final List<FaturaMensalEntity> faturas;

  /// Retorna as faturas do mês/ano especificado.
  List<FaturaMensalEntity> faturasDoMes(int ano, int mes) {
    return faturas.where((f) => f.ano == ano && f.mes == mes).toList();
  }

  /// Soma dos valores não pagos no mês/ano especificado.
  double totalNaoPagoDoMes(int ano, int mes) {
    return faturasDoMes(ano, mes)
        .where((f) => !f.pago)
        .fold(0.0, (soma, f) => soma + f.valor);
  }

  /// Retorna a fatura do mês/ano, ou `null` se não existir.
  FaturaMensalEntity? faturaDoMes(int ano, int mes) {
    final result = faturasDoMes(ano, mes);
    return result.isEmpty ? null : result.first;
  }

  DividaEntity copyWith({
    String? id,
    String? nome,
    bool? mensal,
    Color? cor,
    List<FaturaMensalEntity>? faturas,
  }) {
    return DividaEntity(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      mensal: mensal ?? this.mensal,
      cor: cor ?? this.cor,
      faturas: faturas ?? this.faturas,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DividaEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          mensal == other.mensal &&
          cor == other.cor &&
          listEquals(faturas, other.faturas);

  @override
  int get hashCode => Object.hash(id, nome, mensal, cor, faturas);

  @override
  String toString() => 'DividaEntity(id: $id, nome: $nome, mensal: $mensal, '
      'cor: $cor, faturas: $faturas)';
}

@immutable
class FaturaMensalEntity {
  const FaturaMensalEntity({
    required this.ano,
    required this.mes,
    required this.valor,
    this.pago = false,
  });

  final int ano;
  final int mes;
  final bool pago;
  final double valor;

  FaturaMensalEntity copyWith({
    int? ano,
    int? mes,
    bool? pago,
    double? valor,
  }) {
    return FaturaMensalEntity(
      ano: ano ?? this.ano,
      mes: mes ?? this.mes,
      pago: pago ?? this.pago,
      valor: valor ?? this.valor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaturaMensalEntity &&
          runtimeType == other.runtimeType &&
          ano == other.ano &&
          mes == other.mes &&
          pago == other.pago &&
          valor == other.valor;

  @override
  int get hashCode => Object.hash(ano, mes, pago, valor);

  @override
  String toString() =>
      'FaturaMensalEntity(ano: $ano, mes: $mes, pago: $pago, valor: $valor)';
}
