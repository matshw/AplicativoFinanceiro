import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FinanceiroApp());
}

class FinanceiroApp extends StatefulWidget {
  const FinanceiroApp({super.key});

  @override
  _FinanceiroAppState createState() => _FinanceiroAppState();
}

class _FinanceiroAppState extends State<FinanceiroApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplicativo Financeiro'),
      ),
      body: const Center(
        child: Text('Página inicial do aplicativo'),
      ),
    );
  }
}
