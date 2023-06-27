class FaturaEntity {
  final String idCartao;
  final String ano;
  final String mes;
  final String valorFatura;
  FaturaEntity({
    required this.idCartao,
    required this.ano,
    required this.mes,
    required this.valorFatura,
  });

  Map<String, dynamic> toMap() {
    return {
      'idCartao': idCartao,
      'ano': ano,
      'mes': mes,
      'valorFatura': valorFatura,
    };
  }

  factory FaturaEntity.fromMap(Map<String, dynamic> map) {
    return FaturaEntity(
      idCartao: map['idCartao'] ?? '',
      ano: map['ano'] ?? '',
      mes: map['mes'] ?? '',
      valorFatura: map['valorFatura'] ?? '',
    );
  }

  FaturaEntity copyWith({
    String? idCartao,
    String? ano,
    String? mes,
    String? valorFatura,
  }) {
    return FaturaEntity(
      idCartao: idCartao ?? this.idCartao,
      ano: ano ?? this.ano,
      mes: mes ?? this.mes,
      valorFatura: valorFatura ?? this.valorFatura,
    );
  }
}
