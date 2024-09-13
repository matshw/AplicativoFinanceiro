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
    String? categoria,
    DateTime date,
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
      'categoria': categoria,
      'data': date,
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

  void _showActionSheet(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final descricao = data['descricao'];
    final valor = data['valor'];
    final tipo = data['tipo'];
    final categoria = data['categoria'];
    final dateTimestamp = data['data'];
    final date = dateTimestamp.toDate();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(document);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Remover'),
              onTap: () {
                Navigator.pop(context);
                _removeTransacao(document.id, valor, tipo);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel),
              title: Text('Cancelar'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final descricao = data['descricao'];
    final valor = data['valor'].toString();
    final tipo = data['tipo'];
    final categoria = data['categoria'];
    final dateTimestamp = data['data'];
    final date = dateTimestamp.toDate();

    TextEditingController descricaoController =
        TextEditingController(text: descricao);
    TextEditingController valorController = TextEditingController(text: valor);
    String? _selectedCategory = categoria;
    DateTime _selectedDate = date;

    final Map<String, FaIcon> _gainCategories = {
      'Salário': const FaIcon(FontAwesomeIcons.sackDollar),
      'Freelance': const FaIcon(FontAwesomeIcons.briefcase),
      'Venda': const FaIcon(FontAwesomeIcons.circleDollarToSlot),
      'Comissão': const FaIcon(FontAwesomeIcons.handHoldingDollar),
      'Presente': const FaIcon(FontAwesomeIcons.gift),
      'Consultoria': const FaIcon(FontAwesomeIcons.magnifyingGlassDollar),
      'Outros': const FaIcon(FontAwesomeIcons.circleQuestion),
    };

    final Map<String, FaIcon> _expenseCategories = {
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
      'Outros': const FaIcon(FontAwesomeIcons.circleQuestion),
    };

    void _showDatePicker(StateSetter setState) {
      showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDate: _selectedDate,
        locale: const Locale('pt', 'BR'),
      ).then((pickedDate) {
        if (pickedDate != null && pickedDate != _selectedDate) {
          setState(() {
            _selectedDate = pickedDate;
          });
        }
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Transação'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descricaoController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  TextField(
                    controller: valorController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Valor'),
                  ),
                  const SizedBox(height: 20),
                  if (tipo == 'ganho')
                    FittedBox(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        hint: const Text("Selecione uma categoria de ganho"),
                        items: _gainCategories.keys.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Row(
                              children: [
                                _gainCategories[category]!,
                                const SizedBox(width: 8),
                                Text(category),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                    ),
                  if (tipo == 'gasto')
                    FittedBox(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        hint: const Text("Selecione uma categoria de gasto"),
                        items: _expenseCategories.keys.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Row(
                              children: [
                                _expenseCategories[category]!,
                                const SizedBox(width: 8),
                                Text(category),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () {
                          _showDatePicker(setState);
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateTransacao(
                  document.id,
                  descricaoController.text,
                  double.parse(valorController.text),
                  tipo,
                  _selectedCategory,
                  _selectedDate,
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _updateTransacao(String docID, String descricao, double valor,
      String tipo, String? categoria, DateTime date) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirestoreService firestoreService = FirestoreService();
    firestoreService
        .updateTransacao(
            user.uid, docID, descricao, valor, tipo, categoria, date)
        .then((_) {
      setState(() {});
    }).catchError((error) {});
  }

  void _removeTransacao(String docID, double valor, String tipo) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirestoreService firestoreService = FirestoreService();
    firestoreService.removeTransacao(user.uid, docID, valor, tipo).then((_) {
      setState(() {});
    }).catchError((error) {});
  }

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
                          onTap: () {
                            _showActionSheet(document);
                          },
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
