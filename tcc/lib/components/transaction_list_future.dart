import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tcc/components/transaction_form_gasto.dart';

final NumberFormat currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

final NumberFormat numberFormatter = NumberFormat.decimalPattern('pt_BR');

class FutureTransactionList extends StatefulWidget {
  const FutureTransactionList();

  @override
  State<FutureTransactionList> createState() => _FutureTransactionListState();
}

class _FutureTransactionListState extends State<FutureTransactionList> {
  void _markAsPaid({
    required String uid,
    required String docID,
    required double valor,
    required String tipo,
    required DateTime data,
  }) async {
    FirestoreService _firestoreService = FirestoreService();

    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transacao')
          .doc(docID)
          .get();

      if (docSnapshot.exists && docSnapshot['tipo'] != 'gasto') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('transacao')
            .doc(docID)
            .update({
          'tipo': 'gasto',
          'data': DateTime.now(),
        });

        await _firestoreService.updateInfo(uid, valor, -valor, 'gasto');
      }
    } catch (e) {}
  }

  void _cancelarRecorrencia(String docID) async {
    FirestoreService _firestoreService = FirestoreService();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestoreService.removeTransacao(
          user.uid, docID, 0, 'gasto', DateTime.now());
      setState(() {});
    } catch (e) {}
  }

  void _showChoiceModalBottomSheet({
    required BuildContext context,
    required String uid,
    required String docID,
    required double valor,
    required String tipo,
    required String descricao,
    required DateTime data,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.edit,
                ),
                title: const Text('Editar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(
                    context: context,
                    uid: uid,
                    docID: docID,
                    tipo: tipo,
                    descricao: descricao,
                    valor: valor,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: const Text('Remover',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveDialog(
                    context: context,
                    uid: uid,
                    docID: docID,
                    valor: valor,
                    tipo: tipo,
                    data: data,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.check_circle,
                ),
                title: const Text('Pago',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _markAsPaid(
                    uid: uid,
                    docID: docID,
                    valor: valor,
                    tipo: tipo,
                    data: data,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete,
                ),
                title: Text('Remover recorrência',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  _cancelarRecorrencia(docID);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.cancel,
                ),
                title: const Text('Cancelar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog({
    required BuildContext context,
    required String uid,
    required String docID,
    required String tipo,
    required String descricao,
    required double valor,
  }) {
    final descricaoController = TextEditingController(text: descricao);
    final valueController =
        TextEditingController(text: currencyFormatter.format(valor));

    FirestoreService firestoreService = FirestoreService();
    final mediaQuery = MediaQuery.of(context);
    final avaliableHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Editar Transação"),
          content: SizedBox(
            height: avaliableHeight * 0.15,
            child: Column(
              children: [
                TextField(
                  controller: descricaoController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                firestoreService
                    .updateTransacao(
                  uid,
                  docID,
                  descricaoController.text,
                  double.tryParse(valueController.text) ?? 0.0,
                  tipo,
                )
                    .then((_) {
                  Navigator.of(context).pop();
                });
              },
              child: const Text("Salvar alteração"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveDialog({
    required BuildContext context,
    required String uid,
    required String docID,
    required double valor,
    required String tipo,
    required DateTime data,
  }) {
    FirestoreService firestoreService = FirestoreService();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Remover Transação"),
          content: const Text("Tem certeza que deseja remover esta transação?"),
          actions: [
            TextButton(
              onPressed: () {
                firestoreService
                    .removeTransacao(uid, docID, valor, tipo, data)
                    .then((_) {
                  Navigator.of(context).pop();
                });
              },
              child: const Text("Remover"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Usuário não autenticado."));
    }

    FirestoreService firestoreService = FirestoreService();
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      child: Card(
        elevation: 15,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(10),
          ),
          height: availableHeight * 0.28,
          child: StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getFutureTransactionsStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text("Erro ao carregar dados"),
                );
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("Sem itens"),
                );
              }

              List transacoesList = snapshot.data!.docs;

              return ListView.builder(
                itemCount: transacoesList.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = transacoesList[index];
                  String docID = document.id;

                  Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;
                  String transacaoDescricao = data['descricao'];
                  double transacaoValor = data['valor'];
                  String tipo = data['tipo'];
                  Timestamp dateTimestamp = data['data'];
                  DateTime date = dateTimestamp.toDate();

                  return InkWell(
                    onTap: () {
                      _showChoiceModalBottomSheet(
                        context: context,
                        uid: user.uid,
                        docID: docID,
                        valor: transacaoValor,
                        tipo: tipo,
                        descricao: transacaoDescricao,
                        data: date,
                      );
                    },
                    child: ListTile(
                      title: Text(
                        DateFormat.yMMMMEEEEd('pt_BR').format(date),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color.fromARGB(228, 255, 255, 255),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FittedBox(
                            child: Text(
                              tipo == 'ganho'
                                  ? currencyFormatter.format(transacaoValor)
                                  : "-${currencyFormatter.format(transacaoValor)}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: tipo == 'ganho'
                                    ? Colors.green
                                    : Color.fromARGB(255, 244, 111, 101),
                              ),
                            ),
                          ),
                          Text(
                            transacaoDescricao,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: tipo == 'ganho'
                                  ? Colors.green
                                  : Color.fromARGB(255, 244, 111, 101),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
