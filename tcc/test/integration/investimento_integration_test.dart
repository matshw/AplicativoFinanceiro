import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tcc/models/categoriaRisco.dart';
import 'package:tcc/models/investimento.dart';
import 'package:tcc/firebase_options.dart';

void main() async {
  // Inicialize o Firebase antes de executar os testes
  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  group('Testes do CRUD de investimentos', () {
    final CollectionReference investimentosCollection =
        FirebaseFirestore.instance.collection('investimentos');

    test('Deve criar um investimento no firebase', () async {
      final investimento = Investimento(
        idRisco: '1',
        nome: 'Alto Risco',
        valor: 1000.0,
        descricao: 'Investimento em ações',
        rentabilidade: 5.0,
        dataInvestimento: DateTime(2023, 1, 1),
        dataPrevista: DateTime(2024, 1, 1),
        risco: CategoriaRisco(idRisco: '1', nomeRisco: 'Alto'),
      );

      await investimentosCollection.add({
        'idRisco': investimento.idRisco,
        'nome': investimento.nomeRisco,
        'valor': investimento.valor,
        'descricao': investimento.descricao,
        'rentabilidade': investimento.rentabilidade,
        'dataInvestimento': investimento.dataInvestimento,
        'dataPrevista': investimento.dataPrevista,
      });

      final snapshot = await investimentosCollection.get();
      expect(snapshot.docs.length, greaterThan(0));
      expect(snapshot.docs.first['valor'], 1000.0);
    });

    test('Deve ler um investimento do firebase', () async {
      final snapshot = await investimentosCollection.limit(1).get();
      final doc = snapshot.docs.first;

      expect(doc.exists, true);
      expect(doc['nome'], 'Alto Risco');
    });

    test('Deve atualizar um investimento no firebase', () async {
      final snapshot = await investimentosCollection.limit(1).get();
      final doc = snapshot.docs.first;

      await investimentosCollection.doc(doc.id).update({'valor': 2000.0});

      final updatedDoc = await investimentosCollection.doc(doc.id).get();
      expect(updatedDoc['valor'], 2000.0);
    });

    test('Deve deletar um investimento do firebases', () async {
      final snapshot = await investimentosCollection.limit(1).get();
      final doc = snapshot.docs.first;

      await investimentosCollection.doc(doc.id).delete();

      final deletedDoc = await investimentosCollection.doc(doc.id).get();
      expect(deletedDoc.exists, false);
    });
  });
}
