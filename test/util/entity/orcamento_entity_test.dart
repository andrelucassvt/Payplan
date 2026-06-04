import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/src/util/entity/orcamento_entity.dart';

void main() {
  const cor = Colors.blue;

  SubItemOrcamentoEntity subItem({
    required String id,
    required double valor,
    bool concluido = false,
  }) =>
      SubItemOrcamentoEntity(
        id: id,
        nome: 'Item $id',
        valor: valor,
        concluido: concluido,
      );

  group('OrcamentoEntity.totalOrcamento', () {
    group('sem sub-itens', () {
      test('retorna valor quando não concluído', () {
        const o = OrcamentoEntity(
          id: '1',
          nome: 'Teste',
          cor: cor,
          valor: 150.0,
          concluido: false,
        );
        expect(o.totalOrcamento, 150.0);
      });

      test('retorna 0.0 quando concluído', () {
        const o = OrcamentoEntity(
          id: '1',
          nome: 'Teste',
          cor: cor,
          valor: 150.0,
          concluido: true,
        );
        expect(o.totalOrcamento, 0.0);
      });
    });

    group('com sub-itens', () {
      test('retorna soma de todos quando nenhum concluído', () {
        final o = OrcamentoEntity(
          id: '1',
          nome: 'Teste',
          cor: cor,
          valor: 0,
          subItens: [
            subItem(id: 'a', valor: 100),
            subItem(id: 'b', valor: 50),
          ],
        );
        expect(o.totalOrcamento, 150.0);
      });

      test('exclui sub-itens concluídos da soma', () {
        final o = OrcamentoEntity(
          id: '1',
          nome: 'Teste',
          cor: cor,
          valor: 0,
          subItens: [
            subItem(id: 'a', valor: 100, concluido: true),
            subItem(id: 'b', valor: 50),
          ],
        );
        expect(o.totalOrcamento, 50.0);
      });

      test('retorna 0.0 quando todos os sub-itens concluídos', () {
        final o = OrcamentoEntity(
          id: '1',
          nome: 'Teste',
          cor: cor,
          valor: 0,
          subItens: [
            subItem(id: 'a', valor: 100, concluido: true),
            subItem(id: 'b', valor: 50, concluido: true),
          ],
        );
        expect(o.totalOrcamento, 0.0);
      });
    });
  });
}
