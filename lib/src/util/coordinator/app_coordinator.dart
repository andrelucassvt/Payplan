import 'package:flutter/material.dart';
import 'package:notes_app/src/features/graphic/presenter/graphic_view.dart';
import 'package:notes_app/src/features/novo_cartao/presenter/novo_cartao_view.dart';
import 'package:notes_app/src/util/dto/graphic_dto.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';
import 'package:notes_app/src/util/service/navigation_service.dart';

class AppCoordinator {
  var currentContext = NavigationService.navigatorKey.currentContext;

  dynamic _navegacao(Widget view) {
    return Navigator.of(currentContext!)
        .push(MaterialPageRoute(builder: (_) => view));
  }

  Future<void> navegarNovoCartaoView({
    CartaoEntity? cartaoEntity,
    bool isDivida = false,
  }) async {
    return await _navegacao(NovoCartaoView(
      cartaoEntity: cartaoEntity,
      isDivida: isDivida,
    ));
  }

  Future<void> navegarGraphicView({
    required GraphicDto params,
  }) async {
    return await _navegacao(GraphicView(
      params: GraphicDto(
        cartoes: params.cartoes,
        mesSelecionado: params.mesSelecionado,
      ),
    ));
  }
}
