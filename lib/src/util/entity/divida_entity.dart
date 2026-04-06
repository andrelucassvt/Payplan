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
    this.subDividas = const [],
  });

  final String id;
  final String nome;
  final bool mensal;
  final Color cor;
  final List<FaturaMensalEntity> faturas;
  final List<SubDividaEntity> subDividas;

  /// Retorna as faturas do mês/ano especificado.
  List<FaturaMensalEntity> faturasDoMes(int ano, int mes) {
    return faturas.where((f) => f.ano == ano && f.mes == mes).toList();
  }

  /// Soma dos sub-itens aplicáveis no mês/ano especificado.
  double totalSubDividasDoMes(int ano, int mes) {
    return subDividas
        .where((s) => s.aplicavelNoMes(ano, mes))
        .fold(0.0, (soma, s) => soma + s.valor);
  }

  /// Soma dos valores não pagos no mês/ano especificado (inclui sub-itens).
  double totalNaoPagoDoMes(int ano, int mes) {
    final fatura = faturaDoMes(ano, mes);
    if (!mensal && fatura == null) return 0.0;
    if (fatura?.pago ?? false) return 0.0;
    final valorFatura = fatura?.valor ?? 0.0;
    return valorFatura + totalSubDividasDoMes(ano, mes);
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
    List<SubDividaEntity>? subDividas,
  }) {
    return DividaEntity(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      mensal: mensal ?? this.mensal,
      cor: cor ?? this.cor,
      faturas: faturas ?? this.faturas,
      subDividas: subDividas ?? this.subDividas,
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
          listEquals(faturas, other.faturas) &&
          listEquals(subDividas, other.subDividas);

  @override
  int get hashCode => Object.hash(id, nome, mensal, cor, faturas, subDividas);

  @override
  String toString() => 'DividaEntity(id: $id, nome: $nome, mensal: $mensal, '
      'cor: $cor, faturas: $faturas, subDividas: $subDividas)';
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

@immutable
class SubDividaEntity {
  const SubDividaEntity({
    required this.id,
    required this.nome,
    required this.valor,
    required this.recorrente,
    this.mes,
    this.ano,
  });

  final String id;
  final String nome;
  final double valor;

  /// Se `true`, aplica-se a todos os meses. Se `false`, só ao [mes]/[ano].
  final bool recorrente;
  final int? mes;
  final int? ano;

  bool aplicavelNoMes(int ano, int mes) {
    if (recorrente) return true;
    return this.ano == ano && this.mes == mes;
  }

  SubDividaEntity copyWith({
    String? id,
    String? nome,
    double? valor,
    bool? recorrente,
    int? mes,
    int? ano,
  }) {
    return SubDividaEntity(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      recorrente: recorrente ?? this.recorrente,
      mes: mes ?? this.mes,
      ano: ano ?? this.ano,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubDividaEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          valor == other.valor &&
          recorrente == other.recorrente &&
          mes == other.mes &&
          ano == other.ano;

  @override
  int get hashCode => Object.hash(id, nome, valor, recorrente, mes, ano);

  @override
  String toString() => 'SubDividaEntity(id: $id, nome: $nome, valor: $valor, '
      'recorrente: $recorrente, mes: $mes, ano: $ano)';
}
