part of 'orcamento_cubit.dart';

sealed class OrcamentoState {
  final List<OrcamentoEntity> orcamentos;
  final double totalGeral;

  OrcamentoState({
    required this.orcamentos,
    required this.totalGeral,
  });
}

final class OrcamentoInitial extends OrcamentoState {
  OrcamentoInitial({
    required super.orcamentos,
    required super.totalGeral,
  });
}

final class OrcamentoLoading extends OrcamentoState {
  OrcamentoLoading({
    required super.orcamentos,
    required super.totalGeral,
  });
}

final class OrcamentoSucesso extends OrcamentoState {
  OrcamentoSucesso({
    required super.orcamentos,
    required super.totalGeral,
  });
}
