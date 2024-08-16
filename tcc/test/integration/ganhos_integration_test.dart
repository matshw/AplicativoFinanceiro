import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tcc/models/ganhos.dart';
import 'package:tcc/firebase_options.dart';

void main() async {
  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  group('Testes do CRUD de ganhos', () {
    final CollectionReference ganhosCollection =
        FirebaseFirestore.instance.collection('ganhos');

    test('Deve adicionar um ganho no firebase', () async {
      final ganho = Ganhos(
        id: '1',
        descricao: 'Salário',
        valor: 3000.0,
        dataRecebimento: DateTime(2023, 1, 1),
        idGanho: '1',
        nome: 'Trabalho',
      );

      await ganhosCollection.add({
        'id': ganho.id,
        'descricao': ganho.descricao,
        'valor': ganho.valor,
        'dataRecebimento': ganho.dataRecebimento,
        'idGanho': ganho.idGanho,
        'nome': ganho.nome,
      });

      final snapshot = await ganhosCollection.get();
      expect(snapshot.docs.length, greaterThan(0));
      expect(snapshot.docs.first['valor'], 3000.0);
    });

    test('Deve ler um ganho no firebase', () async {
      final snapshot = await ganhosCollection.limit(1).get();
      final doc = snapshot.docs.first;

      expect(doc.exists, true);
      expect(doc['descricao'], 'Salário');
    });

    test('Deve atualizar um ganho do firebase', () async {
      final snapshot = await ganhosCollection.limit(1).get();
      final doc = snapshot.docs.first;

      await ganhosCollection.doc(doc.id).update({'valor': 3500.0});

      final updatedDoc = await ganhosCollection.doc(doc.id).get();
      expect(updatedDoc['valor'], 3500.0);
    });

    test('Deve deletar um ganho no firebase', () async {
      final snapshot = await ganhosCollection.limit(1).get();
      final doc = snapshot.docs.first;

      await ganhosCollection.doc(doc.id).delete();

      final deletedDoc = await ganhosCollection.doc(doc.id).get();
      expect(deletedDoc.exists, false);
    });
  });
}
