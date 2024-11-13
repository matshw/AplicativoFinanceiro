import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tcc/components/card_balance.dart';
import 'package:tcc/components/transaction_form_economias.dart';
import 'package:tcc/components/transaction_form_ganho.dart';
import 'package:tcc/components/transaction_form_gasto.dart';
import 'package:tcc/components/transaction_list.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tcc/components/transaction_list_future.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScreenMain extends StatefulWidget {
  const ScreenMain();

  @override
  State<ScreenMain> createState() => _ScreenMainState();
}

class _ScreenMainState extends State<ScreenMain> {
  final ValueNotifier<Map<String, double>> balanceNotifier =
      ValueNotifier({'ganhoValue': 0.0, 'saldoValue': 0.0, 'gastoValue': 0.0});

  @override
  void initState() {
    super.initState();
    _loadInitialBalance();
  }

  // Carrega os valores iniciais do Firestore e atualiza balanceNotifier
  Future<void> _loadInitialBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection('users').doc(user.uid).get();

    if (doc.exists && doc.data() != null) {
      balanceNotifier.value = {
        'ganhoValue': doc.data()?['ganhoValue']?.toDouble() ?? 0.0,
        'saldoValue': doc.data()?['saldoValue']?.toDouble() ?? 0.0,
        'gastoValue': doc.data()?['gastoValue']?.toDouble() ?? 0.0,
      };
    }
  }

  void _addTransacao(
      String descricao,
      String categoria,
      String tipo,
      double valor,
      DateTime dataRecebimento,
      String? imagem,
      String meioPagamento) {
    if (tipo == 'ganho') {
      _updateBalanceGanho(valor);
    } else if (tipo == 'gasto') {
      _updateBalanceGasto(valor);
    }
  }

  void _updateBalanceGanho(double value) {
    balanceNotifier.value = {
      'ganhoValue': balanceNotifier.value['ganhoValue']! + value,
      'saldoValue': balanceNotifier.value['saldoValue']! + value,
      'gastoValue': balanceNotifier.value['gastoValue']!,
    };
    _saveBalance();
  }

  void _updateBalanceGasto(double value) {
    balanceNotifier.value = {
      'gastoValue': balanceNotifier.value['gastoValue']! + value,
      'saldoValue': balanceNotifier.value['saldoValue']! - value,
      'ganhoValue': balanceNotifier.value['ganhoValue']!,
    };
    _saveBalance();
  }

  // Atualiza os valores de saldo no Firestore
  Future<void> _saveBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(user.uid).update({
      'ganhoValue': balanceNotifier.value['ganhoValue'],
      'saldoValue': balanceNotifier.value['saldoValue'],
      'gastoValue': balanceNotifier.value['gastoValue'],
    });
  }

  void _openTransactionFormModalCofrinho() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionFormEconomias(),
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
            // Usando o ValueListenableBuilder para observar as mudanças no balanceNotifier
            ValueListenableBuilder<Map<String, double>>(
              valueListenable: balanceNotifier,
              builder: (context, balance, child) {
                return CardBalance(balanceNotifier);
              },
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
        backgroundColor: const Color.fromARGB(255, 59, 66, 72),
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
            label: "Economias",
            onTap: _openTransactionFormModalCofrinho,
          ),
        ],
      ),
    );
  }
}
