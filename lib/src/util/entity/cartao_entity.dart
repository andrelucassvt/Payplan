import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';

class CartaoEntity {
  final String id;
  final String nome;
  final int cor;
  final bool isDivida;
  final bool isMensal;
  final String ano;
  final String mes;
  final List<FaturaEntity> dividas;

  CartaoEntity({
    required this.id,
    required this.nome,
    required this.cor,
    required this.isDivida,
    required this.isMensal,
    required this.ano,
    required this.mes,
    required this.dividas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cor': cor,
      'isDivida': isDivida,
      'isMensal': isMensal,
      'ano': ano,
      'mes': mes,
      'dividas': dividas.map((x) => x.toMap()).toList(),
    };
  }

  factory CartaoEntity.fromMap(Map<String, dynamic> map) {
    return CartaoEntity(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      cor: map['cor']?.toInt() ?? 0,
      isDivida: map['isDivida'] ?? false,
      isMensal: map['isMensal'] ?? false,
      ano: map['ano'] ?? '',
      mes: map['mes'] ?? '',
      dividas: List<FaturaEntity>.from(
          map['dividas']?.map((x) => FaturaEntity.fromMap(x))),
    );
  }

  CartaoEntity copyWith({
    String? id,
    String? nome,
    int? cor,
    bool? isDivida,
    bool? isMensal,
    String? ano,
    String? mes,
    List<FaturaEntity>? dividas,
  }) {
    return CartaoEntity(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cor: cor ?? this.cor,
      isDivida: isDivida ?? this.isDivida,
      isMensal: isMensal ?? this.isMensal,
      ano: ano ?? this.ano,
      mes: mes ?? this.mes,
      dividas: dividas ?? this.dividas,
    );
  }

  String toJson() => json.encode(toMap());

  factory CartaoEntity.fromJson(String source) =>
      CartaoEntity.fromMap(json.decode(source));

  @override
  String toString() {
    return 'CartaoEntity(id: $id, nome: $nome, cor: $cor, isDivida: $isDivida, isMensal: $isMensal, ano: $ano, mes: $mes, dividas: $dividas)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CartaoEntity &&
        other.id == id &&
        other.nome == nome &&
        other.cor == cor &&
        other.isDivida == isDivida &&
        other.isMensal == isMensal &&
        other.ano == ano &&
        other.mes == mes &&
        listEquals(other.dividas, dividas);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nome.hashCode ^
        cor.hashCode ^
        isDivida.hashCode ^
        isMensal.hashCode ^
        ano.hashCode ^
        mes.hashCode ^
        dividas.hashCode;
  }
}
