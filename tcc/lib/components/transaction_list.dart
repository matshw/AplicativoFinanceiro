import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final CollectionReference ganhos =
      FirebaseFirestore.instance.collection('ganhos');
  final DocumentReference userInfo =
      FirebaseFirestore.instance.collection('userInfo').doc('user_info');
  Stream<QuerySnapshot> getGanhosStream() {
    final ganhosStream =
        ganhos.orderBy('dataRecebimento', descending: true).snapshots();
    return ganhosStream;
  }

  Future<void> updateGanho(
    String docID,
    String descricao,
    double valor,
    // String categoria,
  ) {
    return ganhos.doc(docID).update({
      'descricao': descricao,
      'valor': valor,
      // 'categoria': categoria,
    });
  }

  Future<void> removeGanho(String docID, double valorGanho) async {
    await ganhos.doc(docID).delete();

    await userInfo.update({
      'saldoValue': FieldValue.increment(-valorGanho),
      'ganhoValue': FieldValue.increment(-valorGanho)
    });
  }

  Stream<DocumentSnapshot> getSaldoStream() {
    return userInfo.snapshots();
  }

  Future<double> getSaldoTotal() async {
    DocumentSnapshot docSnapshot = await userInfo.get();
    if (docSnapshot.exists) {
      return docSnapshot['saldoValue'] ?? 0.0;
    } else {
      return 0.0;
    }
  }
}

void _showChoiceDialog({
  required BuildContext context,
  required String docID,
  required double valorGanho,
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
              _showEditDialog(context: context, docID: docID);
            },
            child: const Text("Editar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showRemoveDialog(
                  context: context, docID: docID, valorGanho: valorGanho);
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
  required String docID,
}) {
  final descricaoController = TextEditingController();
  final valueController = TextEditingController();
  

  FirestoreService firestoreService = FirestoreService();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Editar Transação"),
        content: SizedBox(
          height: 300,
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
          ElevatedButton(
            onPressed: () {
              firestoreService
                  .updateGanho(docID, descricaoController.text,
                      double.tryParse(valueController.text) ?? 0.0
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
  required String docID,
  required double valorGanho,
}) {
  FirestoreService firestoreService = FirestoreService();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Remover Transação"),
        content: const Text("Tem certeza que deseja remover esta transação?"),
        actions: [
          ElevatedButton(
            onPressed: () {
              firestoreService.removeGanho(docID, valorGanho).then((_) {
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
        stream: firestoreService.getGanhosStream(),
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

          List ganhosList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: ganhosList.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = ganhosList[index];
              String docID = document.id;

              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              String ganhoDescricao = data['descricao'];
              double ganhoValor = data['valor'];
              Timestamp ganhoDataTimestamp = data['dataRecebimento'];
              DateTime ganhoData = ganhoDataTimestamp.toDate();

              return InkWell(
                onTap: () {
                  _showChoiceDialog(
                    context: context,
                    docID: docID,
                    valorGanho: ganhoValor,
                  );
                },
                child: ListTile(
                  title: Text(
                    DateFormat.yMMMMEEEEd('pt_BR').format(ganhoData),
                    style: const TextStyle(fontSize: 15),
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FittedBox(
                        child: Text(
                          "R\$ ${ganhoValor.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      Text(
                        ganhoDescricao,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
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
