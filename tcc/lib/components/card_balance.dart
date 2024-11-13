import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

final NumberFormat numberFormatter = NumberFormat.decimalPattern('pt_BR');

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

  Stream<DocumentSnapshot<Map<String, dynamic>>> getSaldoStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<Map<String, double>> getInfo(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        double ganhoValue = _getDoubleValue(doc.data()?['ganhoValue']);
        double saldoValue = _getDoubleValue(doc.data()?['saldoValue']);
        double gastoValue = _getDoubleValue(doc.data()?['gastoValue']);
        return {
          'ganhoValue': ganhoValue,
          'saldoValue': saldoValue,
          'gastoValue': gastoValue
        };
      } else {
        await _firestore.collection('users').doc(uid).set({
          'ganhoValue': 0.0,
          'saldoValue': 0.0,
          'gastoValue': 0.0,
        });
        return {'ganhoValue': 0.0, 'saldoValue': 0.0, 'gastoValue': 0.0};
      }
    } catch (e) {
      return {'ganhoValue': 0.0, 'saldoValue': 0.0, 'gastoValue': 0.0};
    }
  }
}

// ignore: must_be_immutable
class CardBalance extends StatefulWidget {
  final VoidCallback openForm;
  var ganhoValue;
  var saldoValue;
  var gastoValue;

  CardBalance(this.openForm, this.ganhoValue, this.saldoValue, this.gastoValue);

  @override
  State<CardBalance> createState() => _CardBalanceState();
}

class _CardBalanceState extends State<CardBalance> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  double _getDoubleValue(dynamic value) {
    if (value is int) {
      return value.toDouble(); 
    } else if (value is double) {
      return value;
    } else {
      return 0.0;
    }
  }

  Future<void> _loadInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, double> info = await _firestoreService.getInfo(user.uid);
    setState(() {
      widget.ganhoValue = info['ganhoValue'];
      widget.saldoValue = info['saldoValue'];
      widget.gastoValue = info['gastoValue'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Erro: usuário não autenticado.'));
    }

    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    return Container(
      height: availableHeight * 0.27,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Card(
        elevation: 15,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.secondary,
          ),
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _firestoreService.getSaldoStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Erro ao carregar dados'));
              } else if (snapshot.hasData) {
                var data = snapshot.data?.data();

                if (data == null) {
                  return const Center(child: Text('Nenhum dado disponível'));
                }

                double ganhoValue = _getDoubleValue(data['ganhoValue']);
                double saldoValue = _getDoubleValue(data['saldoValue']);
                double gastoValue = _getDoubleValue(data['gastoValue']);

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              "Saldo atual",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              currencyFormatter.format(saldoValue),
                              style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Ganho",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 90, 204, 94),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              currencyFormatter.format(ganhoValue),
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 90, 204, 94),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Gasto",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 244, 111, 101),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              currencyFormatter.format(gastoValue),
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 244, 111, 101),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const Center(child: Text('Nenhum dado disponível'));
              }
            },
          ),
        ),
      ),
    );
  }
}
