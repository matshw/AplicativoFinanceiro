import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:tcc/components/transaction_list_future.dart';

void main() {
  testWidgets('Deve abrir o dialog de edição e salvar alterações', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FutureTransactionList())));

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    final descricaoField = find.byType(TextField).first;
    final valorField = find.byType(TextField).last;

    await tester.enterText(descricaoField, 'Nova descrição');
    await tester.enterText(valorField, '200.0');
    await tester.tap(find.text('Salvar alteração'));
    await tester.pumpAndSettle();

    expect(find.text('Nova descrição'), findsOneWidget);
    expect(find.text('R\$200.0'), findsOneWidget);
  });
}
