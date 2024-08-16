import 'package:flutter_test/flutter_test.dart';
import 'package:tcc/models/ganhos.dart';

void main() {
  group('Ganhos', () {
    test('Deve criar um novo ganho válido', () {
      final ganho = Ganhos(
        id: '1',
        descricao: 'Salário',
        valor: 3000.0,
        dataRecebimento: DateTime(2023, 1, 1),
        idGanho: '1',
        nome: 'Trabalho',
      );

      expect(ganho.valor, 3000.0);
      expect(ganho.descricao, 'Salário');
      expect(ganho.dataRecebimento, DateTime(2023, 1, 1));
    });
  });
}
