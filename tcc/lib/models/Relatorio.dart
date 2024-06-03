import 'package:tcc/models/Ganhos.dart';
import 'package:tcc/models/Gastos.dart';
import 'package:tcc/models/Investimento.dart';

class Relatorio {
  final Investimento investimento;
  final Gastos gasto;
  final Ganhos ganho;
  final DateTime dataEspeficica;

  Relatorio(
      {required this.investimento,
      required this.gasto,
      required this.ganho,
      required this.dataEspeficica});
}
