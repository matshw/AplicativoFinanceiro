import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tcc/utils/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  group('FirestoreService Tests', () {
    test('Deve adicionar uma transação ao Firestore', () async {
      final firestoreService = FirestoreService();
      String uid = "testeUID";

      await firestoreService.addTransacao(
        uid,
        'Teste Descrição',
        'Teste Categoria',
        'ganho',
        150.0,
        DateTime.now(),
        null,
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transacao')
          .get();

      expect(snapshot.docs.isNotEmpty, true);
      expect(snapshot.docs.first['descricao'], 'Teste Descrição');
      expect(snapshot.docs.first['valor'], 150.0);
    });

    test('Deve atualizar uma transação no Firestore', () async {
      final firestoreService = FirestoreService();
      String uid = "testeUID";

      DocumentReference transacaoRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transacao')
          .add({
        'descricao': 'Descrição Inicial',
        'categoria': 'Categoria',
        'tipo': 'ganho',
        'valor': 100.0,
        'data': DateTime.now(),
      });

      await firestoreService.updateTransacao(
        uid,
        transacaoRef.id,
        'Nova Descrição',
        200.0,
        'ganho',
        'Categoria Atualizada',
        DateTime.now(),
      );

      final updatedDoc = await transacaoRef.get();
      expect(updatedDoc['descricao'], 'Nova Descrição');
      expect(updatedDoc['valor'], 200.0);
    });

    test('Deve remover uma transação do Firestore', () async {
      final firestoreService = FirestoreService();
      String uid = "testeUID";

      DocumentReference transacaoRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transacao')
          .add({
        'descricao': 'Descrição para Remover',
        'categoria': 'Categoria',
        'tipo': 'ganho',
        'valor': 50.0,
        'data': DateTime.now(),
      });

      await firestoreService.removeTransacao(
        uid,
        transacaoRef.id,
        50.0,
        'ganho',
      );

      final removedDoc = await transacaoRef.get();
      expect(removedDoc.exists, false);
    });
  });
}
