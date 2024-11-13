import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

final NumberFormat currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

final NumberFormat numberFormatter = NumberFormat.decimalPattern('pt_BR');

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedMonth = DateFormat('MMMM', 'pt_BR').format(DateTime.now());
  int _selectedYear = DateTime.now().year;
  Map<String, List<Map<String, dynamic>>> ganhoTransactions = {};
  Map<String, List<Map<String, dynamic>>> gastoTransactions = {};
  Map<String, double> ganhoCategorySums = {};
  Map<String, double> gastoCategorySums = {};
  Map<String, double> pagamentoCategorySums = {};
  double totalGanhos = 0.0;
  double totalGastos = 0.0;
  Map<String, List<Map<String, dynamic>>> pagamentoTransactions = {};
  Map<String, double> _goals = {};
  Map<String, double> _expenses = {};
  Map<String, double> _previousMonthExpenses = {};

  final Map<String, Color> ganhoColors = {
    'Salário': Colors.blue,
    'Freelance': Colors.green,
    'Venda': Colors.orange,
    'Comissão': Colors.purple,
    'Presente': Colors.yellow,
    'Consultoria': Colors.red,
    'Outros': Colors.grey,
  };

  final Map<String, Color> gastoColors = {
    'Comida': Colors.blue,
    'Roupas': Colors.green,
    'Lazer': Colors.orange,
    'Transporte': Colors.purple,
    'Saúde': Colors.yellow,
    'Presentes': Colors.red,
    'Educação': Colors.cyan,
    'Outros': Colors.grey,
  };

  final Map<String, Color> pagamentoColors = {
    'Dinheiro': Colors.green,
    'Cartão de Crédito': Colors.blue,
    'Cartão de Débito': Colors.orange,
    'Transferência': Colors.red,
    'Pix': Colors.purple,
    'Boleto': Colors.yellow,
  };
  final Map<String, Color> _categories = {
    'Comida': Colors.blue,
    'Roupas': Colors.green,
    'Lazer': Colors.orange,
    'Transporte': Colors.purple,
    'Saúde': Colors.yellow,
    'Presentes': Colors.red,
    'Educação': Colors.cyan,
    'Beleza': Colors.pink,
    'Emergência': Colors.teal,
    'Reparos': Colors.brown,
    'Streaming': Colors.amber,
    'Serviços': Colors.indigo,
    'Tecnologia': Colors.deepOrange,
    'Outros': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  double _getDoubleValue(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      return 0.0;
    }
  }

  void _loadData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transacao')
        .where('data', isGreaterThanOrEqualTo: startOfMonth)
        .where('data', isLessThanOrEqualTo: endOfMonth)
        .get()
        .then((snapshot) {
      List<Map<String, dynamic>> transacoes = snapshot.docs.map((doc) {
        return doc.data();
      }).toList();

      Map<String, List<Map<String, dynamic>>> ganhos = {};
      Map<String, List<Map<String, dynamic>>> gastos = {};
      Map<String, List<Map<String, dynamic>>> pagamentos = {};
      Map<String, double> ganhoSumByCategory = {};
      Map<String, double> gastoSumByCategory = {};
      Map<String, double> pagamentoSumByCategory = {};
      double totalGanhosTemp = 0.0;
      double totalGastosTemp = 0.0;

      for (var transacao in transacoes) {
        String categoria = transacao['categoria'];
        String tipo = transacao['tipo'];
        double valor = (transacao['valor'] ?? 0.0).toDouble();

        if (tipo == 'ganho') {
          ganhos[categoria] = (ganhos[categoria] ?? [])..add(transacao);
          ganhoSumByCategory[categoria] =
              (ganhoSumByCategory[categoria] ?? 0.0) + valor;
        } else if (tipo == 'gasto') {
          gastos[categoria] = (gastos[categoria] ?? [])..add(transacao);
          gastoSumByCategory[categoria] =
              (gastoSumByCategory[categoria] ?? 0.0) + valor;

          String meioPagamento = transacao['meioPagamento'] ?? 'Outros';
          pagamentoSumByCategory[meioPagamento] =
              (pagamentoSumByCategory[meioPagamento] ?? 0) + valor;
          pagamentos[meioPagamento] = pagamentos[meioPagamento] ?? [];
          pagamentos[meioPagamento]?.add(transacao);
        }
      }

      setState(() {
        totalGanhos = ganhoSumByCategory.values.fold(0.0, (a, b) => a + b);
        totalGastos = gastoSumByCategory.values.fold(0.0, (a, b) => a + b);
        ganhoTransactions = ganhos;
        gastoTransactions = gastos;
        ganhoCategorySums = ganhoSumByCategory;
        gastoCategorySums = gastoSumByCategory;
        pagamentoTransactions = pagamentos;
        pagamentoCategorySums = pagamentoSumByCategory;
      });
    });
  }

  void _selectMonth(BuildContext context) async {
    int tempMonth = _selectedDate.month;
    int tempYear = _selectedYear;

    int? selectedMonth = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Escolha o mês'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: tempMonth,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(DateFormat('MMMM', 'pt_BR')
                            .format(DateTime(0, index + 1))),
                      );
                    }),
                    onChanged: (newValue) {
                      setDialogState(() {
                        tempMonth = newValue!;
                      });
                    },
                  ),
                  DropdownButton<int>(
                    value: tempYear,
                    items: List.generate(50, (index) {
                      int year = DateTime.now().year - 49 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (newValue) {
                      setDialogState(() {
                        tempYear = newValue!;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Selecionar'),
                  onPressed: () {
                    Navigator.of(context).pop(tempMonth);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedMonth != null) {
      setState(() {
        _selectedDate = DateTime(tempYear, selectedMonth);
        _selectedMonth = DateFormat('MMMM', 'pt_BR').format(_selectedDate);
        _selectedYear = tempYear;
        _loadData();
      });
    }
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Relatório de $_selectedMonth $_selectedYear'),
          ),
          _buildPDFSection('Ganhos', ganhoCategorySums, ganhoTransactions),
          pw.SizedBox(height: 20),
          _buildPDFSection('Gastos', gastoCategorySums, gastoTransactions),
          pw.SizedBox(height: 20),
          _buildPDFSection('Meios de Pagamento', pagamentoCategorySums,
              pagamentoTransactions),
          pw.SizedBox(height: 20),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPDFSection(String title, Map<String, double> categorySums,
      Map<String, List<Map<String, dynamic>>> transactions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Categoria', 'Valor'],
          data: categorySums.entries
              .map((entry) =>
                  [entry.key, '${currencyFormatter.format(entry.value)}'])
              .toList(),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Transações:',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        ...transactions.entries.map(
          (entry) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${entry.key}: ${entry.value.length} ${entry.value.length == 1 ? "transação" : "transações"}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                ...entry.value.map((transacao) {
                  String descricao = transacao['descricao'] ?? '';
                  double valor = _getDoubleValue(transacao['valor']);

                  return pw.Text(
                      '$descricao -  ${currencyFormatter.format(valor)}');
                }).toList(),
                pw.SizedBox(height: 10),
              ],
            );
          },
        ).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          'Relatórios Mensais',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            color: Colors.white,
            onPressed: () => _selectMonth(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            color: Colors.white,
            onPressed: _exportPDF,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Relatório de $_selectedMonth $_selectedYear',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            _buildGanhoSection(),
            const SizedBox(height: 20),
            _buildGastoSection(),
            const SizedBox(height: 20),
            _buildPagamentoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGanhoSection() {
    return Column(
      children: [
        const Text(
          'Ganhos',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildPieChart(ganhoCategorySums, ganhoColors),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  const Text(
                    'Total de Ganhos no Mês',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    currencyFormatter.format(totalGanhos),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTransactionList('ganho', ganhoTransactions, ganhoColors),
      ],
    );
  }

  Widget _buildGastoSection() {
    return Column(
      children: [
        const Text(
          'Gastos',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildPieChart(gastoCategorySums, gastoColors),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Total de Gastos no Mês',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    currencyFormatter.format(totalGastos),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTransactionList('gasto', gastoTransactions, gastoColors),
      ],
    );
  }

  Widget _buildPagamentoSection() {
    return Column(
      children: [
        const Text(
          'Meios de Pagamento',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildPieChart(pagamentoCategorySums, pagamentoColors),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTransactionList(
            'pagamento', pagamentoTransactions, pagamentoColors),
      ],
    );
  }

  Widget _buildPieChart(
      Map<String, double> categorySums, Map<String, Color> colors) {
    if (categorySums.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum dado disponível para o mês selecionado.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    List<PieChartSectionData> sections = [];
    categorySums.forEach((category, totalValue) {
      sections.add(
        PieChartSectionData(
          color: colors[category] ?? Colors.grey,
          value: totalValue,
          title: '',
          radius: 60,
          titleStyle: const TextStyle(color: Colors.transparent),
          badgeWidget: Container(
            color: colors[category],
            padding: const EdgeInsets.all(5),
            child: const SizedBox(),
          ),
          badgePositionPercentageOffset: 1.3,
        ),
      );
    });

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 0,
          borderData: FlBorderData(show: false),
          sectionsSpace: 0,
          startDegreeOffset: 0,
        ),
      ),
    );
  }

  Widget _buildTransactionList(
      String tipo,
      Map<String, List<Map<String, dynamic>>> transactions,
      Map<String, Color> colors) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum dado disponível para o mês selecionado.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        String category = transactions.keys.elementAt(index);
        List<Map<String, dynamic>> categoryTransactions =
            transactions[category] ?? [];

        double totalCategoryValue = categoryTransactions.fold(
          0.0,
          (sum, transaction) => sum + transaction['valor'],
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: colors[category],
              radius: 10,
            ),
            title: Text(
              '$category - ${currencyFormatter.format(totalCategoryValue)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Text(
              '${categoryTransactions.length} ${categoryTransactions.length == 1 ? "transação" : "transações"}',
              style: const TextStyle(color: Colors.white),
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            collapsedShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            children: categoryTransactions.map((transaction) {
              String descricao = transaction['descricao'];
              double valor = (transaction['valor'] ?? 0.0).toDouble();
              DateTime data = transaction['data'].toDate();

              return ListTile(
                title: Text(
                  descricao,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(data),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                trailing: Text(
                  currencyFormatter.format(valor),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
