import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tcc/utils/firestore_service.dart';

void main() {
  group('FirestoreService - markAsPaid', () {
    final firestoreService = FirestoreService();

    test('Marca transação como paga e atualiza valor', () async {
      await firestoreService.updateInfo('uid123', 100.0, -100.0);
      
      verify(firestoreService.updateInfo('uid123', 100.0, -100.0)).called(1);
    });
  });
}
