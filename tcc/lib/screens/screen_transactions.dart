import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTransactionsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transacao')
        .orderBy('data', descending: true)
        .snapshots();
  }

  Future<void> updateTransacao(
    String uid,
    String docID,
    String descricao,
    double valor,
    String tipo,
  ) async {
    double difference = 0.0;

    DocumentSnapshot docSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('transacao')
        .doc(docID)
        .get();
    if (docSnapshot.exists) {
      double oldValor = docSnapshot['valor'] ?? 0.0;
      difference = valor - oldValor;
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('transacao')
        .doc(docID)
        .update({
      'descricao': descricao,
      'valor': valor,
    });

    if (tipo == 'ganho') {
      await _firestore.collection('users').doc(uid).update({
        'saldoValue': FieldValue.increment(difference),
        'ganhoValue': FieldValue.increment(difference)
      });
    } else if (tipo == 'gasto') {
      await _firestore.collection('users').doc(uid).update({
        'saldoValue': FieldValue.increment(-difference),
        'gastoValue': FieldValue.increment(difference)
      });
    }
  }

  Future<void> removeTransacao(
      String uid, String docID, double valor, String tipo) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('transacao')
        .doc(docID)
        .delete();

    if (tipo == 'ganho') {
      await _firestore.collection('users').doc(uid).update({
        'saldoValue': FieldValue.increment(-valor),
        'ganhoValue': FieldValue.increment(-valor)
      });
    } else if (tipo == 'gasto') {
      await _firestore.collection('users').doc(uid).update({
        'saldoValue': FieldValue.increment(valor),
        'gastoValue': FieldValue.increment(-valor)
      });
    }
  }

  Stream<DocumentSnapshot> getSaldoStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<double> getSaldoTotal(String uid) async {
    DocumentSnapshot docSnapshot =
        await _firestore.collection('users').doc(uid).get();
    if (docSnapshot.exists) {
      return docSnapshot['saldoValue'] ?? 0.0;
    } else {
      return 0.0;
    }
  }
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _filteredTransactions = [];
  String _selectedFilter = 'Nenhum';

  final Map<String, FaIcon> _categories = {
    'Salário': const FaIcon(FontAwesomeIcons.sackDollar),
    'Freelance': const FaIcon(FontAwesomeIcons.briefcase),
    'Venda': const FaIcon(FontAwesomeIcons.circleDollarToSlot),
    'Comissão': const FaIcon(FontAwesomeIcons.handHoldingDollar),
    'Presente': const FaIcon(FontAwesomeIcons.gift),
    'Consultoria': const FaIcon(FontAwesomeIcons.magnifyingGlassDollar),
    'Outros': const FaIcon(FontAwesomeIcons.circleQuestion),
    'Comida': const FaIcon(FontAwesomeIcons.burger),
    'Roupas': const FaIcon(FontAwesomeIcons.shirt),
    'Lazer': const FaIcon(FontAwesomeIcons.futbol),
    'Transporte': const FaIcon(FontAwesomeIcons.bicycle),
    'Saúde': const FaIcon(FontAwesomeIcons.suitcaseMedical),
    'Presentes': const FaIcon(FontAwesomeIcons.gift),
    'Educação': const FaIcon(FontAwesomeIcons.book),
    'Beleza': const FaIcon(FontAwesomeIcons.paintbrush),
    'Emergência': const FaIcon(FontAwesomeIcons.hospital),
    'Reparos': const FaIcon(FontAwesomeIcons.hammer),
    'Streaming': const FaIcon(FontAwesomeIcons.tv),
    'Serviços': const FaIcon(FontAwesomeIcons.clipboard),
    'Tecnologia': const FaIcon(FontAwesomeIcons.laptop),
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterTransactions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTransactions() {
    setState(() {
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_filteredTransactions.isEmpty) {
      return;
    }
    switch (_selectedFilter) {
      case 'Valor - Maior para Menor':
        _filteredTransactions.sort((a, b) {
          return (b.data() as Map<String, dynamic>)['valor']
              .compareTo((a.data() as Map<String, dynamic>)['valor']);
        });
        break;
      case 'Valor - Menor para Maior':
        _filteredTransactions.sort((a, b) {
          return (a.data() as Map<String, dynamic>)['valor']
              .compareTo((b.data() as Map<String, dynamic>)['valor']);
        });
        break;
      case 'Data - Mais Recente':
        _filteredTransactions.sort((a, b) {
          return (b.data() as Map<String, dynamic>)['data']
              .compareTo((a.data() as Map<String, dynamic>)['data']);
        });
        break;
      case 'Data - Mais Antiga':
        _filteredTransactions.sort((a, b) {
          return (a.data() as Map<String, dynamic>)['data']
              .compareTo((b.data() as Map<String, dynamic>)['data']);
        });
        break;
      default:
        _filteredTransactions = List.from(_filteredTransactions);
        break;
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <String>[
              'Nenhum',
              'Valor - Maior para Menor',
              'Valor - Menor para Maior',
              'Data - Mais Recente',
              'Data - Mais Antiga',
            ].map((String value) {
              return ListTile(
                title: Text(value),
                onTap: () {
                  setState(() {
                    _selectedFilter = value;
                    _applyFilter();
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Erro: usuário não autenticado.'));
    }

    FirestoreService firestoreService = FirestoreService();

    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: mediaQuery.size.width * 0.95,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade300,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none),
                        hintText: "Buscar transação",
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(horizontal: 6),
                        prefixIconColor:
                            const Color.fromARGB(255, 101, 177, 240),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 8.0,
                  ),
                  IconButton(
                    onPressed: _showFilterOptions,
                    icon: Icon(Icons.filter_list),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: availableHeight * 0.05,
            ),
            Container(
              height: availableHeight * 0.7,
              child: StreamBuilder<QuerySnapshot>(
                stream: firestoreService.getTransactionsStream(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text("Erro ao carregar dados"),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("Sem itens"),
                    );
                  }

                  List<DocumentSnapshot> transacoesList = snapshot.data!.docs;

                  if (_searchController.text.isNotEmpty) {
                    _filteredTransactions = transacoesList.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final descricao =
                          data['descricao'].toString().toLowerCase();
                      return descricao
                          .contains(_searchController.text.toLowerCase());
                    }).toList();
                  } else {
                    _filteredTransactions = List.from(transacoesList);
                  }

                  _applyFilter();

                  return ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = _filteredTransactions[index];

                      Map<String, dynamic> data =
                          document.data() as Map<String, dynamic>;
                      String transacaoDescricao = data['descricao'];
                      double transacaoValor = data['valor'];
                      String tipo = data['tipo'];
                      String categoria = data['categoria'];
                      Timestamp dateTimestamp = data['data'];
                      DateTime date = dateTimestamp.toDate();

                      FaIcon? categoryIcon = _categories[categoria.trim()];

                      if (categoryIcon == null) {
                        categoryIcon = const FaIcon(FontAwesomeIcons.question);
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: categoryIcon,
                          title: Text(
                            categoria,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transacaoDescricao,
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                DateFormat.yMMMMEEEEd('pt_BR').format(date),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Text(
                            tipo == 'ganho'
                                ? "R\$ ${transacaoValor.toStringAsFixed(2)}"
                                : "R\$ -${transacaoValor.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  tipo == 'ganho' ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
