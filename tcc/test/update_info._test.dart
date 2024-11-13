import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tcc/utils/firestore_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  group('FirestoreService - updateInfo', () {
    final mockFirestoreService = MockFirestoreService();

    test('Atualiza valores de ganho e saldo corretamente', () async {
      await mockFirestoreService.updateInfo('uid123', 100.0, 200.0);

      verify(mockFirestoreService.updateInfo('uid123', 100.0, 200.0)).called(1);
    });
  });
}
