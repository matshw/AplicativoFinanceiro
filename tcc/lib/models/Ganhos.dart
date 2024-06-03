import 'package:tcc/models/categoriaGanho.dart';

class Ganhos extends CategoriaGanho {
  final String id;
  final String descricao;
  final double valor;
  final DateTime dataRecebimento;

  Ganhos(
      {required this.id,
      required this.descricao,
      required this.valor,
      required this.dataRecebimento,
      required super.idGanho,
      required super.nome});
}
