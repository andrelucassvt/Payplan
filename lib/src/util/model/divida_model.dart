import 'package:flutter/material.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';

class FaturaMensalModel extends FaturaMensalEntity {
  const FaturaMensalModel({
    required super.ano,
    required super.mes,
    required super.valor,
    super.pago,
  });

  factory FaturaMensalModel.fromJson(Map<String, dynamic> json) {
    return FaturaMensalModel(
      ano: json['ano'] as int,
      mes: json['mes'] as int,
      pago: json['pago'] as bool? ?? false,
      // (json['valor'] as num) trata int e double vindos do JSON
      valor: (json['valor'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ano': ano,
      'mes': mes,
      'pago': pago,
      'valor': valor,
    };
  }

  factory FaturaMensalModel.fromEntity(FaturaMensalEntity entity) {
    return FaturaMensalModel(
      ano: entity.ano,
      mes: entity.mes,
      pago: entity.pago,
      valor: entity.valor,
    );
  }
}

class DividaModel extends DividaEntity {
  const DividaModel({
    required super.id,
    required super.nome,
    required super.mensal,
    required super.cor,
    required super.faturas,
  });

  factory DividaModel.fromJson(Map<String, dynamic> json) {
    return DividaModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      mensal: json['mensal'] as bool,
      cor: Color(json['cor'] as int),
      faturas: (json['faturas'] as List<dynamic>)
          .map((e) => FaturaMensalModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nome': nome,
      'mensal': mensal,
      'cor': cor.toARGB32(),
      'faturas':
          faturas.map((f) => FaturaMensalModel.fromEntity(f).toJson()).toList(),
    };
  }

  factory DividaModel.fromEntity(DividaEntity entity) {
    return DividaModel(
      id: entity.id,
      nome: entity.nome,
      mensal: entity.mensal,
      cor: entity.cor,
      faturas: entity.faturas,
    );
  }
}
