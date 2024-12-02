part of 'home_cubit.dart';

sealed class HomeState {
  final MesesEnum mesAtual;

  HomeState({required this.mesAtual});
}

final class HomeInitial extends HomeState {
  HomeInitial({required super.mesAtual});
}

final class HomeMudarMesAtual extends HomeState {
  HomeMudarMesAtual({required super.mesAtual});
}
