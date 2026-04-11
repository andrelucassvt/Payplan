import 'package:flutter/material.dart';
import 'package:notes_app/src/util/entity/orcamento_entity.dart';

class SubItemOrcamentoModel extends SubItemOrcamentoEntity {
  const SubItemOrcamentoModel({
    required super.id,
    required super.nome,
    required super.valor,
  });

  factory SubItemOrcamentoModel.fromJson(Map<String, dynamic> json) {
    return SubItemOrcamentoModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      valor: (json['valor'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nome': nome,
      'valor': valor,
    };
  }

  factory SubItemOrcamentoModel.fromEntity(SubItemOrcamentoEntity entity) {
    return SubItemOrcamentoModel(
      id: entity.id,
      nome: entity.nome,
      valor: entity.valor,
    );
  }
}

class OrcamentoModel extends OrcamentoEntity {
  const OrcamentoModel({
    required super.id,
    required super.nome,
    required super.cor,
    required super.valor,
    super.subItens = const [],
  });

  factory OrcamentoModel.fromJson(Map<String, dynamic> json) {
    return OrcamentoModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      cor: Color(json['cor'] as int),
      valor: (json['valor'] as num).toDouble(),
      subItens: ((json['sub-itens'] as List<dynamic>?) ?? [])
          .map((e) => SubItemOrcamentoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nome': nome,
      'cor': cor.toARGB32(),
      'valor': valor,
      'sub-itens': subItens
          .map((s) => SubItemOrcamentoModel.fromEntity(s).toJson())
          .toList(),
    };
  }

  factory OrcamentoModel.fromEntity(OrcamentoEntity entity) {
    return OrcamentoModel(
      id: entity.id,
      nome: entity.nome,
      cor: entity.cor,
      valor: entity.valor,
      subItens: entity.subItens,
    );
  }
}
