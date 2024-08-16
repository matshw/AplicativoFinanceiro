import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final DocumentReference userInfo =
      FirebaseFirestore.instance.collection('userInfo').doc('user_info');

  Stream<DocumentSnapshot> getSaldoStream() {
    return userInfo.snapshots();
  }

  Future<Map<String, double>> getInfo() async {
    try {
      DocumentSnapshot doc = await userInfo.get();
      if (doc.exists) {
        double ganhoValue = doc['ganhoValue'] ?? 0.0;
        double saldoValue = doc['saldoValue'] ?? 0.0;
        double gastoValue = doc['gastoValue'] ?? 0.0;
        return {
          'ganhoValue': ganhoValue,
          'saldoValue': saldoValue,
          'gastoValue': gastoValue
        };
      } else {
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
  FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    Map<String, double> info = await _firestoreService.getInfo();
    setState(() {
      widget.ganhoValue = info['ganhoValue'];
      widget.saldoValue = info['saldoValue'];
      widget.gastoValue = info['gastoValue'];
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getSaldoStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Erro ao carregar dados'));
            } else if (snapshot.hasData) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
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
                              FittedBox(
                                child: Text(
                                  "Gasto",
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 18),
                                ),
                              ),
                              FittedBox(
                                child: Text(
                                  "R\$ ${gastoValue.toStringAsFixed(2)}",
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 8),
                          Align(
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
