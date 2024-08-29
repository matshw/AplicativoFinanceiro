import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTransactionsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transacao')
        .orderBy('data', descending: true)
        .snapshots();
  }

  Future<void> updateTransacao(
    String uid,
    String docID,
    String descricao,
    double valor,
    String tipo,
  ) async {
    double difference = 0.0;

    DocumentSnapshot docSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('transacao')
        .doc(docID)
        .get();
    if (docSnapshot.exists) {
      double oldValor = docSnapshot['valor'] ?? 0.0;
      difference = valor - oldValor;
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('transacao')
        .doc(docID)
        .update({
      'descricao': descricao,
      'valor': valor,
    });

    if (tipo == 'ganho') {
      await _firestore.collection('users').doc(uid).update({
        'saldoValue': FieldValue.increment(difference),
        'ganhoValue': FieldValue.increment(difference)
      });
    } else if (tipo == 'gasto') {
      await _firestore.collection('users').doc(uid).update({
        'saldoValue': FieldValue.increment(-difference),
        'gastoValue': FieldValue.increment(difference)
      });
    }
  }

  Future<void> removeTransacao(
    String uid,
    String docID,
    double valor,
    String tipo,
  ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('transacao')
        .doc(docID)
        .delete();

    if (tipo == 'ganho') {
      await _firestore.collection('users').doc(uid).update({
        'saldoValue': FieldValue.increment(-valor),
        'ganhoValue': FieldValue.increment(-valor)
      });
    } else if (tipo == 'gasto') {
      await _firestore.collection('users').doc(uid).update({
        'saldoValue': FieldValue.increment(valor),
        'gastoValue': FieldValue.increment(-valor)
      });
    }
  }
}

void _showChoiceDialog({
  required BuildContext context,
  required String uid,
  required String docID,
  required double valor,
  required String tipo,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Escolha uma opção"),
        content: const Text("Deseja editar ou remover esta transação?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditDialog(
                  context: context, uid: uid, docID: docID, tipo: tipo);
            },
            child: const Text("Editar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showRemoveDialog(
                  context: context,
                  uid: uid,
                  docID: docID,
                  valor: valor,
                  tipo: tipo);
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

void _showEditDialog({
  required BuildContext context,
  required String uid,
  required String docID,
  required String tipo,
}) {
  final descricaoController = TextEditingController();
  final valueController = TextEditingController();

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
                  .removeTransacao(uid, docID, valor, tipo)
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

class TransactionList extends StatelessWidget {
  const TransactionList();

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
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 165, 226, 245),
        border: Border.all(
          color: const Color.fromARGB(255, 165, 226, 245),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      height: availableHeight * 0.38,
      child: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getTransactionsStream(user.uid),
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
                  _showChoiceDialog(
                    context: context,
                    uid: user.uid,
                    docID: docID,
                    valor: transacaoValor,
                    tipo: tipo,
                  );
                },
                child: ListTile(
                  title: Text(
                    DateFormat.yMMMMEEEEd('pt_BR').format(date),
                    style: const TextStyle(fontSize: 15),
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FittedBox(
                        child: Text(
                          tipo == 'ganho'
                              ? "R\$ ${transacaoValor.toStringAsFixed(2)}"
                              : "R\$ -${transacaoValor.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 18,
                            color: tipo == 'ganho' ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      Text(
                        transacaoDescricao,
                        style: TextStyle(
                          fontSize: 18,
                          color: tipo == 'ganho' ? Colors.green : Colors.red,
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
    );
  }
}