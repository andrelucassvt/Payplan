part of 'home_cubit.dart';

sealed class HomeState {
  final MesesEnum mesAtual;
  final int anoAtual;
  final bool isDividas;
  final List<DividaEntity> dividas;

  HomeState({
    required this.mesAtual,
    required this.anoAtual,
    required this.isDividas,
    required this.dividas,
  });
}

final class HomeInitial extends HomeState {
  HomeInitial({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
    required super.dividas,
  });
}

final class HomeDividasSucesso extends HomeState {
  HomeDividasSucesso({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
    required super.dividas,
  });
}

final class HomeDividasLoading extends HomeState {
  HomeDividasLoading({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
    required super.dividas,
  });
}

final class HomeMudarMesAtual extends HomeState {
  HomeMudarMesAtual({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
    required super.dividas,
  });
}

final class HomeMudarListagem extends HomeState {
  HomeMudarListagem({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
    required super.dividas,
  });
}
