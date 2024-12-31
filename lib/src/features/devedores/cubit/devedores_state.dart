part of 'devedores_cubit.dart';

sealed class DevedoresState {
  final List<DevedoresEntity> devedores;
  final double totalValorDevedor;

  DevedoresState({
    required this.devedores,
    required this.totalValorDevedor,
  });
}

final class DevedoresInitial extends DevedoresState {
  DevedoresInitial({
    required super.devedores,
    required super.totalValorDevedor,
  });
}

final class DevedoresLoading extends DevedoresState {
  DevedoresLoading({
    required super.devedores,
    required super.totalValorDevedor,
  });
}

final class DevedoresSucesso extends DevedoresState {
  DevedoresSucesso({
    required super.devedores,
    required super.totalValorDevedor,
  });
}

final class DevedoresError extends DevedoresState {
  DevedoresError({
    required super.devedores,
    required super.totalValorDevedor,
  });
}
