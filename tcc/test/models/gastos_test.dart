import 'package:flutter_test/flutter_test.dart';
import 'package:tcc/models/gastos.dart';
import 'package:tcc/models/categoriaGasto.dart';

void main() {
  group('Gastos', () {
    test('Deve ser criado um novo gasto válido', () {
      final gasto = Gastos(
        id: '1',
        descricao: 'Compra de material',
        dataPagamento: DateTime(2023, 1, 1),
        estadoPagamento: true,
        valor: 150.0,
        idGasto: '1',
        nome: 'Família',
      );

      expect(gasto.valor, 150.0);
      expect(gasto.descricao, 'Compra de material');
      expect(gasto.dataPagamento, DateTime(2023, 1, 1));
      expect(gasto.estadoPagamento, true);
    });
  });
}
