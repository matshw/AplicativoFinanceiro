import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTransacao(
    String uid,
    String descricao,
    String categoria,
    String tipo,
    double valor,
    DateTime data,
    String? imagem,
    String meioPagamento,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('transacao')
          .add({
        'descricao': descricao,
        'categoria': categoria,
        'tipo': tipo,
        'valor': valor,
        'data': data,
        'imagem': imagem ?? '',
        'meioPagamento': meioPagamento,
      });
    } catch (e) {
      print("Erro ao adicionar transação: $e");
    }
  }

  Stream<QuerySnapshot> getFutureTransactionsStream(String uid) {
    DateTime now = DateTime.now();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transacao')
        .where('data', isGreaterThanOrEqualTo: now)
        .snapshots();
  }

  Future<void> updateTransacao(
    String uid,
    String docID,
    String descricao,
    double valor,
    String tipo, {
    String? categoria,
    DateTime? data,
    String? meioPagamento,
  }) async {
    try {
      DocumentReference transacaoRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('transacao')
          .doc(docID);

      Map<String, dynamic> updateData = {
        'descricao': descricao,
        'valor': valor,
        'tipo': tipo,
      };

      if (categoria != null) updateData['categoria'] = categoria;
      if (data != null) updateData['data'] = data;
      if (meioPagamento != null) updateData['meioPagamento'] = meioPagamento;

      await transacaoRef.update(updateData);
      print("Transação atualizada com sucesso!");
    } catch (e) {
      print("Erro ao atualizar transação: $e");
    }
  }

  Future<void> updateInfo(
    String uid,
    double valor,
    double saldoValue,
    String tipo,
  ) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      double currentGanhoValue = doc['ganhoValue'] ?? 0.0;
      double currentGastoValue = doc['gastoValue'] ?? 0.0;
      double currentSaldoValue = doc['saldoValue'] ?? 0.0;

      if (tipo == 'ganho') {
        await _firestore.collection('users').doc(uid).update({
          'ganhoValue': currentGanhoValue + valor,
          'saldoValue': currentSaldoValue + saldoValue,
        });
      } else if (tipo == 'gasto') {
        await _firestore.collection('users').doc(uid).update({
          'gastoValue': currentGastoValue + valor,
          'saldoValue': currentSaldoValue + saldoValue,
        });
      }
    } catch (e) {
      print("Erro ao atualizar informações: $e");
    }
  }

  Future<void> removeTransacao(
      String uid, String docID, double valor, String tipo) async {
    try {
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
    } catch (e) {
      print("Erro ao remover transação: $e");
    }
  }

  Future<void> removeRecurrence(String uid, String docID) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('recurring_transactions')
          .doc(docID)
          .delete();
      print("Recorrência removida com sucesso!");
    } catch (e) {
      print("Erro ao remover recorrência: $e");
    }
  }
}

class FutureTransactionList extends StatelessWidget {
  const FutureTransactionList();

  Future<void> _markAsPaid({
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
    } catch (e) {
      print("Erro ao marcar como pago: $e");
    }
  }

  void _showChoiceModalBottomSheet({
    required BuildContext context,
    required String uid,
    required String docID,
    required double valor,
    required String tipo,
    required String descricao,
    required DateTime data,
    bool isRecurring = false,
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
                leading: Icon(Icons.edit),
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
                leading: Icon(Icons.check_circle),
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
              if (isRecurring)
                ListTile(
                  leading: Icon(Icons.cancel),
                  title: const Text('Remover recorrência',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    FirestoreService().removeRecurrence(uid, docID);
                  },
                ),
              ListTile(
                leading: Icon(Icons.cancel),
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

  Future<void> _removeRecurrence(String uid, String docID) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recurring_transactions')
        .doc(docID)
        .delete();
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Editar Transação"),
          content: Column(
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Usuário não autenticado."));
    }

    FirestoreService firestoreService = FirestoreService();

    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getFutureTransactionsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Erro ao carregar dados"));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Sem itens futuros"));
        }

        List<DocumentSnapshot> transacoesList = snapshot.data!.docs;

        return Container(
          height: 500,
          child: ListView.builder(
            itemCount: transacoesList.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = transacoesList[index];
              String docID = document.id;

              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              String transacaoDescricao = data['descricao'];
              double transacaoValor = (data['valor'] ?? 0.0).toDouble();
              String tipo = data['tipo'];
              Timestamp dateTimestamp = data['data'];
              DateTime date = dateTimestamp.toDate();
              bool isRecurring = data['tipo'] == 'gasto_recorrente';

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
                    isRecurring: isRecurring,
                  );
                },
                child: ListTile(
                  title: Text(
                    DateFormat.yMMMMEEEEd('pt_BR').format(date),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    transacaoDescricao,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  trailing: Text(
                    currencyFormatter.format(transacaoValor),
                    style: TextStyle(
                      fontSize: 18,
                      color: tipo == 'gasto' ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
