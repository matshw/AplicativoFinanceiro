import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tcc/components/appbar_cofrinho.dart';

final NumberFormat currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

final NumberFormat numberFormatter = NumberFormat.decimalPattern('pt_BR');

class EconomiesScreen extends StatelessWidget {
  const EconomiesScreen({Key? key}) : super(key: key);

  void _showInvestmentOptions(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String docId = doc.id;
    final String descricao = data['descricao'];
    final double valorAtual = data['valor'];

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Adicionar valor'),
              onTap: () {
                Navigator.pop(context);
                _showAddValueDialog(context, docId, valorAtual);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove),
              title: const Text('Retirar valor'),
              onTap: () {
                Navigator.pop(context);
                _showRemoveValueDialog(context, docId, valorAtual);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico'),
              onTap: () {
                Navigator.pop(context);
                _showHistoryDialog(context, docId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Excluir'),
              onTap: () {
                Navigator.pop(context);
                _deleteInvestment(context, docId, valorAtual);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteInvestment(BuildContext context, String docId, double valor) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('investments')
        .doc(docId)
        .delete()
        .then((_) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'valorTotal': FieldValue.increment(-valor),
      });
    });
  }

  void _showAddValueDialog(
      BuildContext context, String docId, double valorAtual) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final TextEditingController valorController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar valor ao investimento'),
          content: TextField(
            controller: valorController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor a adicionar'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final double valorAdicionado =
                    double.tryParse(valorController.text) ?? 0.0;

                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('investments')
                    .doc(docId)
                    .update({
                  'valor': FieldValue.increment(valorAdicionado),
                  'historico': FieldValue.arrayUnion([
                    {'valor': valorAdicionado, 'data': DateTime.now()}
                  ])
                }).then((_) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'valorTotal': FieldValue.increment(valorAdicionado),
                  });
                });

                Navigator.pop(context);
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveValueDialog(
      BuildContext context, String docId, double valorAtual) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final TextEditingController valorController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Retirar valor'),
          content: TextField(
            controller: valorController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor a retirar'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final double valorRetirado =
                    double.tryParse(valorController.text) ?? 0.0;

                if (valorRetirado <= valorAtual) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('investments')
                      .doc(docId)
                      .update({
                    'valor': FieldValue.increment(-valorRetirado),
                    'historico': FieldValue.arrayUnion([
                      {'valor': -valorRetirado, 'data': DateTime.now()}
                    ])
                  }).then((_) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'valorTotal': FieldValue.increment(-valorRetirado),
                    });
                  });
                }

                Navigator.pop(context);
              },
              child: const Text('Retirar'),
            ),
          ],
        );
      },
    );
  }

  void _showHistoryDialog(BuildContext context, String docId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('investments')
              .doc(docId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final List historico = data['historico'] ?? [];

            return AlertDialog(
              title: const Text('Histórico de investimentos'),
              content: Container(
                height: 200,
                width: 300,
                child: ListView.builder(
                  itemCount: historico.length,
                  itemBuilder: (context, index) {
                    final entry = historico[index];
                    final double valor = entry['valor'];
                    final DateTime data = (entry['data'] as Timestamp).toDate();
                    return ListTile(
                      title: Text(
                        valor < 0
                            ? '- R\$ ${currencyFormatter.format(valor.abs())}'
                            : 'R\$ ${currencyFormatter.format(valor)}',
                      ),
                      subtitle:
                          Text(DateFormat.yMMMMEEEEd('pt_BR').format(data)),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final avaliableHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Usuário não autenticado.'));
    }

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Column(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Card(
                    elevation: 15,
                    child: Container(
                      padding: EdgeInsets.only(),
                      height: avaliableHeight * 0.2,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          double totalEconomizado = 0.0;
                          var investments =
                              snapshot.data!.data() as Map<String, dynamic>;
                          if (investments.containsKey('valorTotal')) {
                            totalEconomizado = investments['valorTotal'];
                          }
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Total Economizado',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    currencyFormatter.format(totalEconomizado),
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: avaliableHeight * 0.03,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('investments')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final investments = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: investments.length,
                    itemBuilder: (context, index) {
                      final doc = investments[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final double valor = data['valor'];
                      final double valorDesejado = data['valorDesejado'] ?? 0.0;

                      return Container(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: data['imagem'] != null
                                  ? CircleAvatar(
                                      backgroundImage:
                                          FileImage(File(data['imagem'])),
                                      radius: 30,
                                    )
                                  : CircleAvatar(
                                      child: Icon(Icons.money),
                                      radius: 30,
                                    ),
                              title: Text(
                                data['descricao'],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'Rubik',
                                  color: Colors.grey.shade100,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    child: Text(
                                      '${currencyFormatter.format(valor)} / ${currencyFormatter.format(valorDesejado)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'Rubik',
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: valor / valorDesejado,
                                    backgroundColor: Colors.grey.shade700,
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                    minHeight: 6,
                                  ),
                                ],
                              ),
                              onTap: () {
                                _showInvestmentOptions(context, doc);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
