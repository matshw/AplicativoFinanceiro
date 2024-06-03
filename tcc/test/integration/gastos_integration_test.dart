import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tcc/models/gastos.dart';
import 'package:tcc/firebase_options.dart';

void main() async {
  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  group('Testes do CRUD de gastos', () {
    final CollectionReference gastosCollection =
        FirebaseFirestore.instance.collection('gastos');

    test('Deve adicionar um gasto no firebase', () async {
      final gasto = Gastos(
        id: '1',
        descricao: 'Compra de material',
        dataPagamento: DateTime(2023, 1, 1),
        estadoPagamento: true,
        valor: 150.0,
        idGasto: '1',
        nome: 'Essencial',
      );

      await gastosCollection.add({
        'id': gasto.id,
        'descricao': gasto.descricao,
        'dataPagamento': gasto.dataPagamento,
        'estadoPagamento': gasto.estadoPagamento,
        'valor': gasto.valor,
        'idGasto': gasto.idGasto,
        'nome': gasto.nome,
      });

      final snapshot = await gastosCollection.get();
      expect(snapshot.docs.length, greaterThan(0));
      expect(snapshot.docs.first['valor'], 150.0);
    });

    test('Deve atualizar um gasto no firebase', () async {
      final snapshot = await gastosCollection.limit(1).get();
      final doc = snapshot.docs.first;

      expect(doc.exists, true);
      expect(doc['descricao'], 'Compra de material');
    });

    test('Deve atualizar um gasto no firebase', () async {
      final snapshot = await gastosCollection.limit(1).get();
      final doc = snapshot.docs.first;

      await gastosCollection.doc(doc.id).update({'valor': 200.0});

      final updatedDoc = await gastosCollection.doc(doc.id).get();
      expect(updatedDoc['valor'], 200.0);
    });

    test('Deve remover um gasto no firebase', () async {
      final snapshot = await gastosCollection.limit(1).get();
      final doc = snapshot.docs.first;

      await gastosCollection.doc(doc.id).delete();

      final deletedDoc = await gastosCollection.doc(doc.id).get();
      expect(deletedDoc.exists, false);
    });
  });
}
