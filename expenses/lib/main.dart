import 'package:flutter/material.dart';
import './models/transactions.dart';

void main(List<String> args) {
  runApp(const ExpensesAPP());
}

class ExpensesAPP extends StatelessWidget {
  const ExpensesAPP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final _transactions = [
    Transaction(
        id: '1', title: 'novo tenis', value: 310.00, date: DateTime.now()),
    Transaction(id: '2', title: 'conta', value: 100.00, date: DateTime.now())
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Despesas Pessoais"),
        ),
        body: const Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              child: Card(
                color: Colors.blue,
                child: Text("Grafico"),
              ),
            ),
            Card(
              child: Text("Lista de transacoes"),
            )
          ],
        ));
  }
}
