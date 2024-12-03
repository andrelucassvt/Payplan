import 'package:flutter/material.dart';

class DividaEntity {
  final String id;
  final String nome;
  final bool mensal;
  final Color cor;
  final List<FaturaMensalEntity> faturas;

  DividaEntity({
    required this.id,
    required this.nome,
    required this.mensal,
    required this.cor,
    required this.faturas,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nome': nome,
      'mensal': mensal,
      'cor': cor.value,
      'faturas': faturas.map((x) => x.toMap()).toList(),
    };
  }

  factory DividaEntity.fromJson(Map<String, dynamic> map) {
    return DividaEntity(
      id: map['id'] as String,
      nome: map['nome'] as String,
      mensal: map['mensal'] as bool,
      cor: Color(map['cor'] as int),
      faturas: List<FaturaMensalEntity>.from(
        (map['faturas'] as List<dynamic>).map<FaturaMensalEntity>(
          (x) => FaturaMensalEntity.fromJson(x as Map<String, dynamic>),
        ),
      ),
    );
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
}

class FaturaMensalEntity {
  final int ano;
  final int mes;
  final bool pago;
  final double valor;
  FaturaMensalEntity({
    required this.ano,
    required this.mes,
    required this.valor,
    this.pago = false,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ano': ano,
      'mes': mes,
      'pago': pago,
      'valor': valor,
    };
  }

  factory FaturaMensalEntity.fromJson(Map<String, dynamic> map) {
    return FaturaMensalEntity(
      ano: map['ano'] as int,
      mes: map['mes'] as int,
      pago: map['pago'] as bool,
      valor: map['valor'] as double,
    );
  }

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
}
