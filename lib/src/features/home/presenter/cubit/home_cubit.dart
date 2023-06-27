import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';
import 'package:notes_app/src/util/usecases/atualizar_cartao_usecase.dart';
import 'package:notes_app/src/util/usecases/buscar_cartoes_usecase.dart';
import 'package:notes_app/src/util/usecases/remover_cartao_usecase.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required this.buscarCartoesUsecase,
    required this.atualizarCartaoUsecase,
    required this.removerCartaoUsecase,
  }) : super(HomeInitial(
          mesSelecionado: [],
          meses: [],
          cartoes: [],
          dividas: [],
          anoAtual: '',
          valorTotalDaFatura: 0,
        ));
  final BuscarCartoesUsecase buscarCartoesUsecase;
  final AtualizarCartaoUsecase atualizarCartaoUsecase;
  final RemoverCartaoUsecase removerCartaoUsecase;

  Future<void> inicializar({
    bool disableLoading = false,
  }) async {
    if (!disableLoading) {
      emit(HomeLoading(
        mesSelecionado: state.mesSelecionado,
        meses: [],
        cartoes: [],
        dividas: [],
        anoAtual: state.anoAtual,
        valorTotalDaFatura: state.valorTotalDaFatura,
      ));
    }
    DateTime now = DateTime.now();
    List<String> months = [];

    for (int i = 1; i <= 12; i++) {
      DateTime monthDate = DateTime(now.year, i);
      String month = _getMonthName(monthDate.month);
      months.add(month);
    }

    _buscarCartoes(
      months: months,
      now: now,
    );
  }

  Future<void> _buscarCartoes({
    required List<String> months,
    required DateTime now,
  }) async {
    final result = await buscarCartoesUsecase();
    result.fold((error) {
      emit(
        HomeError(
          meses: months,
          mesSelecionado: [_getMonthName(now.month)],
          cartoes: [],
          dividas: [],
          anoAtual: state.anoAtual,
          error: error,
          valorTotalDaFatura: state.valorTotalDaFatura,
        ),
      );
    }, (cartoes) {
      final mesAtual = state.mesSelecionado.isNotEmpty
          ? state.mesSelecionado.first
          : _getMonthName(now.month);

      // // Filtrar cartões com divida true
      // final cartoesComDivida =
      //     cartoes.where((cartao) => cartao.isDivida).toList();

      final valorTotalFatura =
          cartoes.fold(0.0, (double valorAcumulado, cartao) {
        final dividasDoMes = cartao.dividas.where((divida) {
          return divida.ano == now.year.toString() && divida.mes == mesAtual;
        }).toList();

        final valorFaturasDoMes =
            dividasDoMes.fold(0.0, (double valorAcumulado, divida) {
          return valorAcumulado + double.parse(divida.valorFatura);
        });

        return valorAcumulado + valorFaturasDoMes;
      });
      emit(
        HomeSucess(
          meses: months,
          anoAtual: now.year.toString(),
          mesSelecionado: state.mesSelecionado.isEmpty
              ? [_getMonthName(now.month)]
              : state.mesSelecionado,
          cartoes: cartoes.isEmpty ? [] : cartoes,
          dividas: [],
          valorTotalDaFatura: valorTotalFatura,
        ),
      );
    });
  }

  Future<void> mudarMesSelecionado(String mes) async {
    emit(HomeSucess(
      meses: state.meses,
      mesSelecionado: [mes],
      cartoes: state.cartoes,
      anoAtual: state.anoAtual,
      dividas: state.dividas,
      valorTotalDaFatura: state.valorTotalDaFatura,
    ));
    inicializar();
  }

  Future<void> atualizarCartao(CartaoEntity cartaoEntity) async {
    emit(HomeLoading(
      mesSelecionado: state.mesSelecionado,
      meses: state.meses,
      cartoes: state.cartoes,
      dividas: state.dividas,
      anoAtual: state.anoAtual,
      valorTotalDaFatura: state.valorTotalDaFatura,
    ));
    final result = await atualizarCartaoUsecase(
      cartaoEntity: cartaoEntity,
    );

    result.fold(
      (error) => emit(
        HomeError(
          meses: state.meses,
          mesSelecionado: state.mesSelecionado,
          cartoes: [],
          dividas: [],
          error: error,
          anoAtual: state.anoAtual,
          valorTotalDaFatura: state.valorTotalDaFatura,
        ),
      ),
      (sucesso) {
        inicializar(
          disableLoading: true,
        );
      },
    );
  }

  Future<void> deleterCartao(CartaoEntity cartaoEntity) async {
    final result = await removerCartaoUsecase(cartaoEntity: cartaoEntity);
    result.fold(
      (_) {
        emit(
          HomeError(
            meses: state.meses,
            mesSelecionado: state.mesSelecionado,
            cartoes: [],
            dividas: [],
            error: _,
            anoAtual: state.anoAtual,
            valorTotalDaFatura: state.valorTotalDaFatura,
          ),
        );
      },
      (_) {
        inicializar();
      },
    );
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'JAN';
      case 2:
        return 'FEV';
      case 3:
        return 'MAR';
      case 4:
        return 'ABR';
      case 5:
        return 'MAI';
      case 6:
        return 'JUN';
      case 7:
        return 'JUL';
      case 8:
        return 'AGO';
      case 9:
        return 'SET';
      case 10:
        return 'OUT';
      case 11:
        return 'NOV';
      case 12:
        return 'DEZ';
      default:
        return '';
    }
  }
}
