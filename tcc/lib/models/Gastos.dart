import 'package:tcc/models/categoriaGasto.dart';

class Gastos extends CategoriaGasto {
  final double valor;
  final String id;
  final String descricao;
  final DateTime dataPagamento;
  final bool estadoPagamento;

  Gastos(
      {required this.id,
      required this.descricao,
      required this.dataPagamento,
      required this.estadoPagamento,
      required this.valor,
      required super.nome,
      required super.idGasto});
}
