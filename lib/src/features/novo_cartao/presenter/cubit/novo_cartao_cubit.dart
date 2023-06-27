import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';
import 'package:notes_app/src/util/usecases/atualizar_cartao_usecase.dart';
import 'package:notes_app/src/util/usecases/salvar_cartao_usecase.dart';

part 'novo_cartao_state.dart';

class NovoCartaoCubit extends Cubit<NovoCartaoState> {
  NovoCartaoCubit({
    required this.salvarCartaoUsecase,
    required this.atualizarCartaoUsecase,
  }) : super(
          NovoCartaoInitial(
            nomeEmpresa: '',
            corSelecionada: [],
            cores: [],
          ),
        );

  final SalvarCartaoUsecase salvarCartaoUsecase;
  final AtualizarCartaoUsecase atualizarCartaoUsecase;

  final List<Color> _cores = [
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

  void iniciar() {
    emit(
      NovoCartaoSucesso(
        nomeEmpresa: '',
        cores: _cores,
        corSelecionada: [_cores.first],
      ),
    );
  }

  void mudarNomeEmpresa(String nome) {
    emit(
      NovoCartaoSucesso(
        nomeEmpresa: nome,
        cores: state.cores,
        corSelecionada: state.corSelecionada,
      ),
    );
  }

  Future<void> atualizarCartao(CartaoEntity cartaoEntity) async {
    emit(
      NovoCartaoLoading(
        nomeEmpresa: state.nomeEmpresa,
        corSelecionada: state.corSelecionada,
        cores: state.cores,
      ),
    );
    final result = await atualizarCartaoUsecase(
      cartaoEntity: cartaoEntity,
    );
    result.fold(
      (erro) => emit(
        NovoCartaoErro(
          nomeEmpresa: state.nomeEmpresa,
          corSelecionada: state.corSelecionada,
          cores: state.cores,
          erroMessage: erro,
        ),
      ),
      (_) => emit(
        NovoCartaoSucessoSalvo(
          nomeEmpresa: state.nomeEmpresa,
          corSelecionada: state.corSelecionada,
          cores: state.cores,
        ),
      ),
    );
  }

  void mudarCorSelecionada(Color cor) {
    emit(
      NovoCartaoSucesso(
        nomeEmpresa: state.nomeEmpresa,
        cores: state.cores,
        corSelecionada: [cor],
      ),
    );
  }

  Future<void> salvarCartao({
    required CartaoEntity cartaoEntity,
  }) async {
    emit(
      NovoCartaoLoading(
        nomeEmpresa: state.nomeEmpresa,
        corSelecionada: state.corSelecionada,
        cores: state.cores,
      ),
    );

    final result = await salvarCartaoUsecase(cartaoEntity: cartaoEntity);

    result.fold(
      (erro) => emit(
        NovoCartaoErro(
          nomeEmpresa: state.nomeEmpresa,
          corSelecionada: state.corSelecionada,
          cores: state.cores,
          erroMessage: erro,
        ),
      ),
      (_) => emit(
        NovoCartaoSucessoSalvo(
          nomeEmpresa: state.nomeEmpresa,
          corSelecionada: state.corSelecionada,
          cores: state.cores,
        ),
      ),
    );
  }
}
