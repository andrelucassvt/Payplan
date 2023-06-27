part of 'home_cubit.dart';

abstract class HomeState {
  final List<String> meses;
  final List<String> mesSelecionado;
  final List<CartaoEntity> cartoes;
  final List<CartaoEntity> dividas;
  final String anoAtual;
  final double valorTotalDaFatura;
  HomeState({
    required this.meses,
    required this.mesSelecionado,
    required this.cartoes,
    required this.anoAtual,
    required this.valorTotalDaFatura,
    required this.dividas,
  });
}

class HomeInitial extends HomeState {
  HomeInitial({
    required super.meses,
    required super.mesSelecionado,
    required super.cartoes,
    required super.anoAtual,
    required super.valorTotalDaFatura,
    required super.dividas,
  });
}

class HomeLoading extends HomeState {
  HomeLoading({
    required super.meses,
    required super.mesSelecionado,
    required super.cartoes,
    required super.anoAtual,
    required super.valorTotalDaFatura,
    required super.dividas,
  });
}

class HomeSucess extends HomeState {
  HomeSucess({
    required super.meses,
    required super.mesSelecionado,
    required super.cartoes,
    required super.anoAtual,
    required super.valorTotalDaFatura,
    required super.dividas,
  });
}

class HomeError extends HomeState {
  final Exception error;
  HomeError({
    required super.meses,
    required super.mesSelecionado,
    required this.error,
    required super.cartoes,
    required super.anoAtual,
    required super.valorTotalDaFatura,
    required super.dividas,
  });
}
