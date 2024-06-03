import 'package:tcc/models/categoriaRisco.dart';

class Investimento extends CategoriaRisco {
  final CategoriaRisco risco;
  final double valor;
  final String descricao;
  final double rentabilidade;
  final DateTime dataInvestimento;
  final DateTime dataPrevista;

  Investimento({
    required super.idRisco,
    required super.nomeRisco,
    required this.valor,
    required this.descricao,
    required this.rentabilidade,
    required this.dataInvestimento,
    required this.dataPrevista,
    required this.risco,
  });

  
}
