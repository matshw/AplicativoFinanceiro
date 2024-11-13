import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _getDoubleValue(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      return 0.0;
    }
  }

  Future<void> addTransacao(
    String uid,
    String descricao,
    String categoria,
    String tipo,
    double valor,
    DateTime data,
    String? imagem,
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
      });
    } catch (e) {
    }
  }

  Future<void> updateInfo(
    String uid,
    double ganhoValue,
    double saldoValue,
  ) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      double currentGanhoValue = _getDoubleValue(doc['ganhoValue']);
      double currentSaldoValue = _getDoubleValue(doc['saldoValue']);

      await _firestore.collection('users').doc(uid).update({
        'ganhoValue': currentGanhoValue + ganhoValue,
        'saldoValue': currentSaldoValue + saldoValue,
      });
    } catch (e) {
    }
  }

  Future<Map<String, double>> getInfo(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        double ganhoValue = _getDoubleValue(doc['ganhoValue']);
        ;
        double saldoValue = _getDoubleValue(doc['saldoValue']);
        ;
        return {'ganhoValue': ganhoValue, 'saldoValue': saldoValue};
      } else {
        return {'ganhoValue': 0.0, 'saldoValue': 0.0};
      }
    } catch (e) {
      return {'ganhoValue': 0.0, 'saldoValue': 0.0};
    }
  }

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
    String? categoria,
    DateTime date,
  ) async {
    double difference = 0.0;

    DocumentSnapshot docSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('transacao')
        .doc(docID)
        .get();
    if (docSnapshot.exists) {
      double oldValor = _getDoubleValue(docSnapshot['valor']);
      ;
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
      'categoria': categoria,
      'data': Timestamp.fromDate(date),
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

  Stream<DocumentSnapshot> getSaldoStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<double> getSaldoTotal(String uid) async {
    DocumentSnapshot docSnapshot =
        await _firestore.collection('users').doc(uid).get();
    if (docSnapshot.exists) {
      return _getDoubleValue(docSnapshot['saldoValue']);
    } else {
      return 0.0;
    }
  }

  Stream<QuerySnapshot> getCategoriesStream() {
    return _firestore.collection('categories').snapshots();
  }

  Future<void> addCategory(String name, int iconCode) async {
    await _firestore.collection('categories').add({
      'name': name,
      'icon': iconCode.toString(),
    });
  }
}
