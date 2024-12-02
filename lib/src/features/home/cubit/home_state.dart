part of 'home_cubit.dart';

sealed class HomeState {
  final MesesEnum mesAtual;
  final int anoAtual;
  final bool isDividas;

  HomeState({
    required this.mesAtual,
    required this.anoAtual,
    required this.isDividas,
  });
}

final class HomeInitial extends HomeState {
  HomeInitial({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
  });
}

final class HomeMudarMesAtual extends HomeState {
  HomeMudarMesAtual({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
  });
}

final class HomeMudarListagem extends HomeState {
  HomeMudarListagem({
    required super.mesAtual,
    required super.anoAtual,
    required super.isDividas,
  });
}
