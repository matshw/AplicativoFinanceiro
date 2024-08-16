class Gastos {
  final double valor;
  final String id;
  final String descricao;
  final DateTime dataPagamento;
  final String categoria;
  final String imagem;
  final String modoPagamento;

  Gastos(
    this.categoria,
    this.imagem,
    this.modoPagamento, {
    required this.id,
    required this.descricao,
    required this.dataPagamento,
    required this.valor,
  });
}
