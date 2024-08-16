import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tcc/components/appbar_customized.dart';
import 'package:tcc/components/card_balance.dart';
import 'package:tcc/components/transaction_form_ganho.dart';
import 'package:tcc/components/transaction_form_gasto.dart';
import 'package:tcc/components/transaction_list.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class ScreenMain extends StatefulWidget {
  const ScreenMain({super.key});

  @override
  State<ScreenMain> createState() => _ScreenMainState();
}

class _ScreenMainState extends State<ScreenMain> {
  double _gasto = 0.00;
  double _ganho = 0.00;
  double _saldoTotal = 0.00;
  final ValueNotifier<Map<String, double>> balanceNotifier =
      ValueNotifier({'ganhoValue': 0.0, 'saldoValue': 0.0, 'gastoValue': 0.0});
  final ValueNotifier<Map<String, double>> balanceNotifierGasto =
      ValueNotifier({'saldoValue': 0.0, 'gastoValue': 0.0});

  void _addGanho(String description, String category, double value,
      DateTime date, String imagem) {
    setState(() {
      _updateBalance(value);
    });
  }

  void _addGasto(
    String descricao,
    String categoria,
    double valor,
  ) {
    // DateTime dataPagamento, String imagem) {
    setState(() {
      _updateBalanceGasto(valor);
    });
  }

  void _updateBalanceGasto(double value) {
    balanceNotifierGasto.value = {
      'gastoValue': balanceNotifier.value['gastoValue']! + value,
      'saldoValue': balanceNotifier.value['saldoValue']! - value,
    };
  }

  void _updateBalance(double value) {
    balanceNotifier.value = {
      'ganhoValue': balanceNotifier.value['ganhoValue']! + value,
      'saldoValue': balanceNotifier.value['saldoValue']! + value,
    };
  }

  void _openTransactionFormModalGanho(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TransactionForm(_addGanho, balanceNotifier);
      },
    );
  }

  void _openTransactionFormModalGasto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TransactionFormGasto(
          balanceNotifierGasto,
          _addGasto,
        );
      },
    );
  }

  void _openForm() {
    _openTransactionFormModalGanho(context);
  }

  void _openFormGasto() {
    _openTransactionFormModalGasto(context);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final avaliableHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 248, 244),
      appBar: AppbarCustomized(_openForm),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: avaliableHeight * 0.02,
            ),
            CardBalance(_openForm, _ganho, _saldoTotal, _gasto),
            SizedBox(
              height: avaliableHeight * 0.04,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Container(
                alignment: Alignment.topLeft,
                child: const Text(
                  "Histórico de transações",
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            const TransactionList(),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: FontAwesomeIcons.bars,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        children: [
          SpeedDialChild(
            shape: CircleBorder(),
            backgroundColor: Colors.green,
            child: FaIcon(FontAwesomeIcons.arrowUp),
            label: "Ganho",
            onTap: _openForm,
          ),
          SpeedDialChild(
            shape: CircleBorder(),
            backgroundColor: Colors.red,
            child: FaIcon(FontAwesomeIcons.arrowDown),
            label: "Gasto",
            onTap: _openFormGasto,
          )
        ],
      ),
    );
  }
}
