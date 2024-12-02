part of 'home_cubit.dart';

sealed class HomeState {
  final MesesEnum mesAtual;
  final int anoAtual;

  HomeState({
    required this.mesAtual,
    required this.anoAtual,
  });
}

final class HomeInitial extends HomeState {
  HomeInitial({
    required super.mesAtual,
    required super.anoAtual,
  });
}

final class HomeMudarMesAtual extends HomeState {
  HomeMudarMesAtual({
    required super.mesAtual,
    required super.anoAtual,
  });
}
