part of 'home_cubit.dart';

sealed class HomeState {
  final MesesEnum mesAtual;
  final int anoAtual;
  final bool isDividas;
  final List<DividaEntity> dividas;
  final double totalGastos;
  final double salarioFixo;

  HomeState({
    required this.mesAtual,
    required this.anoAtual,
    required this.isDividas,
    required this.dividas,
    required this.totalGastos,
    required this.salarioFixo,
  });
}

final class HomeInitial extends HomeState {
  HomeInitial({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
    required super.dividas,
    required super.totalGastos,
    required super.salarioFixo,
  });
}

final class HomeVersaoNova extends HomeState {
  HomeVersaoNova({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
    required super.dividas,
    required super.totalGastos,
    required super.salarioFixo,
  });
}

final class HomeDividasSucesso extends HomeState {
  HomeDividasSucesso({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
    required super.dividas,
    required super.totalGastos,
    required super.salarioFixo,
  });
}

final class HomeDividasLoading extends HomeState {
  HomeDividasLoading({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
    required super.dividas,
    required super.totalGastos,
    required super.salarioFixo,
  });
}

final class HomeMudarMesAtual extends HomeState {
  HomeMudarMesAtual({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
    required super.dividas,
    required super.totalGastos,
    required super.salarioFixo,
  });
}

final class HomeMudarListagem extends HomeState {
  HomeMudarListagem({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
    required super.dividas,
    required super.totalGastos,
    required super.salarioFixo,
  });
}
