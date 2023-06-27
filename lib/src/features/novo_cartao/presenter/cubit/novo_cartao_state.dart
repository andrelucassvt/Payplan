part of 'novo_cartao_cubit.dart';

abstract class NovoCartaoState {
  final String nomeEmpresa;
  final List<Color> cores;
  final List<Color> corSelecionada;
  NovoCartaoState({
    required this.nomeEmpresa,
    required this.corSelecionada,
    required this.cores,
  });
}

class NovoCartaoInitial extends NovoCartaoState {
  NovoCartaoInitial(
      {required super.nomeEmpresa,
      required super.corSelecionada,
      required super.cores});
}

class NovoCartaoLoading extends NovoCartaoState {
  NovoCartaoLoading(
      {required super.nomeEmpresa,
      required super.corSelecionada,
      required super.cores});
}

class NovoCartaoSucesso extends NovoCartaoState {
  NovoCartaoSucesso(
      {required super.nomeEmpresa,
      required super.corSelecionada,
      required super.cores});
}

class NovoCartaoSucessoSalvo extends NovoCartaoState {
  NovoCartaoSucessoSalvo(
      {required super.nomeEmpresa,
      required super.corSelecionada,
      required super.cores});
}

class NovoCartaoErro extends NovoCartaoState {
  final Exception erroMessage;
  NovoCartaoErro({
    required super.nomeEmpresa,
    required super.corSelecionada,
    required super.cores,
    required this.erroMessage,
  });
}
