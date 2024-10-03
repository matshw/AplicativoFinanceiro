import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tcc/components/appbar_customized.dart';
import 'package:tcc/components/card_balance.dart';
import 'package:tcc/components/transaction_form_cofrinho.dart';
import 'package:tcc/components/transaction_form_ganho.dart';
import 'package:tcc/components/transaction_form_gasto.dart';
import 'package:tcc/components/transaction_list.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tcc/components/transaction_list_future.dart';

class ScreenMain extends StatefulWidget {
  const ScreenMain();

  @override
  State<ScreenMain> createState() => _ScreenMainState();
}

class _ScreenMainState extends State<ScreenMain> {
  final ValueNotifier<Map<String, double>> balanceNotifier =
      ValueNotifier({'ganhoValue': 0.0, 'saldoValue': 0.0, 'gastoValue': 0.0});

  void _addTransacao(
      String descricao,
      String categoria,
      String tipo,
      double valor,
      DateTime dataRecebimento,
      String? imagem,
      String meioPagamento) {
    setState(() {
      if (tipo == 'ganho') {
        _updateBalanceGanho(valor);
      } else if (tipo == 'gasto') {
        _updateBalanceGasto(valor);
      }
    });
  }

  void _updateBalanceGanho(double value) {
    balanceNotifier.value = {
      'ganhoValue': balanceNotifier.value['ganhoValue']! + value,
      'saldoValue': balanceNotifier.value['saldoValue']! + value,
      'gastoValue': balanceNotifier.value['gastoValue']!,
    };
  }

  void _updateBalanceGasto(double value) {
    balanceNotifier.value = {
      'gastoValue': balanceNotifier.value['gastoValue']! + value,
      'saldoValue': balanceNotifier.value['saldoValue']! - value,
      'ganhoValue': balanceNotifier.value['ganhoValue']!,
    };
  }

  void _openTransactionFormModalCofrinho() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionFormCofrinho(),
      ),
    );
  }

  void _openTransactionFormModalGanho() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TransactionForm(_addTransacao, balanceNotifier);
      },
    );
  }

  void _openTransactionFormModalGasto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TransactionFormGasto(balanceNotifier, _addTransacao);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: availableHeight * 0.02,
            ),
            CardBalance(
              _openTransactionFormModalGanho,
              balanceNotifier.value['ganhoValue'] ?? 0.0,
              balanceNotifier.value['saldoValue'] ?? 0.0,
              balanceNotifier.value['gastoValue'] ?? 0.0,
            ),
            SizedBox(
              height: availableHeight * 0.02,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Container(
                alignment: Alignment.topLeft,
                child: const Text(
                  "Histórico de Transações",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const TransactionList(),
            SizedBox(
              height: availableHeight * 0.02,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Container(
                alignment: Alignment.topLeft,
                child: const Text(
                  "Transações Pendentes",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            FutureTransactionList(),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        backgroundColor: Color.fromARGB(255, 59, 66, 72),
        icon: FontAwesomeIcons.plus,
        foregroundColor: Colors.white,
        overlayOpacity: 0.4,
        children: [
          SpeedDialChild(
            shape: const CircleBorder(),
            backgroundColor: Colors.green,
            child: const FaIcon(FontAwesomeIcons.arrowUp),
            label: "Ganho",
            onTap: _openTransactionFormModalGanho,
          ),
          SpeedDialChild(
            shape: const CircleBorder(),
            backgroundColor: Colors.red,
            child: const FaIcon(FontAwesomeIcons.arrowDown),
            label: "Gasto",
            onTap: _openTransactionFormModalGasto,
          ),
          SpeedDialChild(
            shape: const CircleBorder(),
            backgroundColor: Colors.orange,
            child: const FaIcon(FontAwesomeIcons.piggyBank),
            label: "Cofrinho",
            onTap: _openTransactionFormModalCofrinho,
          ),
        ],
      ),
    );
  }
}
