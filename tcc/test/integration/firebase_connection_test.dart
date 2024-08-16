import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tcc/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Teste para conexão do firebase', () {
    setUpAll(() async {
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    test('Conecta ao firestore', () async {
      try {
        Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        final firestore = FirebaseFirestore.instance;
        final doc = await firestore.collection('test').doc('connection').get();
        if (!doc.exists) {
          await firestore
              .collection('test')
              .doc('connection')
              .set({'connected': true});
        }
        final fetchedDoc =
            await firestore.collection('test').doc('connection').get();
        expect(fetchedDoc.exists, true);
        expect(fetchedDoc.data()!['connected'], true);
      } catch (e) {
        fail('Falha ao conectar o firestore: $e');
      }
    });

    test('Obtém uma coleção do firestore', () async {
      try {
        Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        final firestore = FirebaseFirestore.instance;
        final snapshot = await firestore.collection('teste').get();
        expect(snapshot.docs.isNotEmpty, true);
      } catch (e) {
        fail('Falha ao obter coleção do Firestore: $e');
      }
    });
  });
}
