import 'package:notes_app/src/util/entity/cartao_entity.dart';

class GraphicDto {
  final List<CartaoEntity> cartoes;
  final String mesSelecionado;
  GraphicDto({
    required this.cartoes,
    required this.mesSelecionado,
  });
}
