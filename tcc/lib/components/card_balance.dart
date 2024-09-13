import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getSaldoStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<Map<String, double>> getInfo(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        double ganhoValue = doc.data()?['ganhoValue']?.toDouble() ?? 0.0;
        double saldoValue = doc.data()?['saldoValue']?.toDouble() ?? 0.0;
        double gastoValue = doc.data()?['gastoValue']?.toDouble() ?? 0.0;
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
      print("Erro ao obter informações: $e");
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
    final avaliableHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    return Container(
      height: avaliableHeight * 0.27,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(255, 165, 226, 245),
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

              double ganhoValue = data['ganhoValue'] ?? 0.0;
              double saldoValue = data['saldoValue'] ?? 0.0;
              double gastoValue = data['gastoValue'] ?? 0.0;

              return Padding(
                padding: const EdgeInsets.only(
                    bottom: 30.0, left: 10.0, right: 10.0, top: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FittedBox(
                                    child: Text(
                                      "Ganho",
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 18),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  FittedBox(
                                    child: Text(
                                      "R\$ ${ganhoValue.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 18,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          const FittedBox(
                            child: Text(
                              "Saldo atual",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          FittedBox(
                            child: Text(
                              "R\$ ${saldoValue.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const FittedBox(
                                child: Text(
                                  "Gasto",
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 18),
                                ),
                              ),
                              FittedBox(
                                child: Text(
                                  "R\$ ${gastoValue.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Align(
                            alignment: Alignment.bottomLeft,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  color: Colors.red,
                                ),
                              ],
                            ),
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
    );
  }
}
