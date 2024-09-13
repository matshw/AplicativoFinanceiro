
class Ganhos {
  final String id;
  final String descricao;
  final double valor;
  final DateTime dataRecebimento;
  final String categoria;
  final String imagem;


  Ganhos({
    required this.imagem,
    required this.id,
    required this.categoria,
    required this.descricao,
    required this.valor,
    required this.dataRecebimento,
  });
}
