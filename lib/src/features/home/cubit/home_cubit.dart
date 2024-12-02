import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/src/util/enum/meses_enum.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit()
      : super(
          HomeInitial(
            mesAtual: MesesEnum.values.firstWhere(
              (element) => element.id == DateTime.now().month,
            ),
            anoAtual: DateTime.now().year,
          ),
        );

  void mudarMesAtual(MesesEnum mes) {
    emit(
      HomeMudarMesAtual(
        mesAtual: mes,
        anoAtual: state.anoAtual,
      ),
    );
  }

  void mudarAnoAtual(int ano) {
    emit(
      HomeMudarMesAtual(
        mesAtual: state.mesAtual,
        anoAtual: ano,
      ),
    );
  }
}
