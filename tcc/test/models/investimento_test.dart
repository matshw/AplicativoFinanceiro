import 'package:flutter_test/flutter_test.dart';
import 'package:tcc/models/Investimento.dart';
import 'package:tcc/models/categoriaRisco.dart';

void main() {
  group('Investimento', () {
    test('Deve ser criado um novo investimento válido', () {
      final risco = CategoriaRisco(idRisco: '1', nomeRisco: 'Alto');
      final investimento = Investimento(
        nomeRisco: 'Alto',
        idRisco: '1',
        risco: risco,
        valor: 1000.0,
        descricao: 'Investimento em renda fixa',
        rentabilidade: 5.0,
        dataInvestimento: DateTime(2023, 1, 1),
        dataPrevista: DateTime(2024, 1, 1),
      );

      expect(investimento.valor, 1000.0);
      expect(investimento.descricao, 'Investimento em renda fixa');
      expect(investimento.rentabilidade, 5.0);
      expect(investimento.dataInvestimento, DateTime(2023, 1, 1));
      expect(investimento.dataPrevista, DateTime(2024, 1, 1));
    });
  });
}
