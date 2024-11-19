import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tcc/screens/screen_categories.dart';
import 'package:tcc/screens/screen_categories_gasto.dart';
import 'package:tcc/screens/screen_payments.dart';

final NumberFormat currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

final NumberFormat numberFormatter = NumberFormat.decimalPattern('pt_BR');

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
    String? meioPagamento,
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
      'meioPagamento': meioPagamento,
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
    final String? imagem = data['imagem'];

    final tipo = data['tipo'];
    final categoria = data['categoria'] ?? "Categoria nao encontrada";
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
              title: Text(
                'Editar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(document);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text(
                'Remover',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _removeTransacao(document.id, valor, tipo);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel),
              title: Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            if (imagem != null && imagem.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text(
                  'Ver imagem',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showImageDialog(context, imagem);
                },
              ),
          ],
        );
      },
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Imagem anexada"),
          content: Image.network(imageUrl),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Fechar"),
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
    final categoria = data['categoria'] ?? "Categoria nao encontrada";
    final meioPagamento =
        data['meioPagamento'] ?? "Meio de pagamento nao encontrado";
    final dateTimestamp = data['data'];
    final date = dateTimestamp.toDate();

    TextEditingController descricaoController =
        TextEditingController(text: descricao);
    TextEditingController valorController = TextEditingController(text: valor);
    String? _selectedCategory = categoria;
    String? _selectedPaymentMethod = meioPagamento;
    DateTime _selectedDate = date;

    void _selectCategory(StateSetter setState) {
      if (tipo == 'ganho') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectCategoryScreen(
              onCategorySelected: (selectedCategory, icon) {
                setState(() {
                  _selectedCategory = selectedCategory;
                });
              },
            ),
          ),
        ).then((_) {
          setState(() {});
        });
      } else if (tipo == 'gasto') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectGastoCategoryScreen(
              onCategorySelected: (selectedCategory, icon) {
                setState(() {
                  _selectedCategory = selectedCategory;
                });
              },
            ),
          ),
        ).then((_) {
          setState(() {});
        });
      }
    }

    void _selectPaymentMethod(StateSetter setState) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectPaymentMethodScreen(
            onPaymentMethodSelected: (selectedMethod, icon) {
              setState(() {
                _selectedPaymentMethod = selectedMethod;
              });
            },
          ),
        ),
      ).then((_) {
        setState(() {});
      });
    }

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
                  ElevatedButton(
                    onPressed: () => _selectCategory(setState),
                    child: Text(_selectedCategory != null
                        ? _selectedCategory!
                        : 'Selecionar Categoria'),
                  ),
                  if (tipo == 'gasto')
                    ElevatedButton(
                      onPressed: () => _selectPaymentMethod(setState),
                      child: Text(_selectedPaymentMethod != null
                          ? _selectedPaymentMethod!
                          : 'Selecionar Meio de Pagamento'),
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
                  _selectedPaymentMethod,
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
      String tipo, String? categoria, DateTime date, String? meioPagamento) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirestoreService firestoreService = FirestoreService();
    firestoreService
        .updateTransacao(
      user.uid,
      docID,
      descricao,
      valor,
      tipo,
      categoria ?? "Categoria nao esppecificada",
      date,
      tipo == 'gasto'
          ? meioPagamento ?? 'Meio de pagamento não especificado'
          : null,
    )
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
    'Salário': const FaIcon(
      FontAwesomeIcons.sackDollar,
      color: Colors.white54,
    ),
    'Freelance': const FaIcon(
      FontAwesomeIcons.briefcase,
      color: Colors.white54,
    ),
    'Venda': const FaIcon(
      FontAwesomeIcons.circleDollarToSlot,
      color: Colors.white54,
    ),
    'Comissão': const FaIcon(
      FontAwesomeIcons.handHoldingDollar,
      color: Colors.white54,
    ),
    'Presente': const FaIcon(
      FontAwesomeIcons.gift,
      color: Colors.white54,
    ),
    'Consultoria': const FaIcon(
      FontAwesomeIcons.magnifyingGlassDollar,
      color: Colors.white54,
    ),
    'Outros': const FaIcon(
      FontAwesomeIcons.circleQuestion,
      color: Colors.white54,
    ),
    'Alimentação': const FaIcon(
      FontAwesomeIcons.burger,
      color: Colors.white54,
    ),
    'Roupas': const FaIcon(
      FontAwesomeIcons.shirt,
      color: Colors.white54,
    ),
    'Lazer': const FaIcon(
      FontAwesomeIcons.futbol,
      color: Colors.white54,
    ),
    'Transporte': const FaIcon(
      FontAwesomeIcons.bicycle,
      color: Colors.white54,
    ),
    'Saúde': const FaIcon(
      FontAwesomeIcons.suitcaseMedical,
      color: Colors.white54,
    ),
    'Presentes': const FaIcon(
      FontAwesomeIcons.gift,
      color: Colors.white54,
    ),
    'Educação': const FaIcon(
      FontAwesomeIcons.book,
      color: Colors.white54,
    ),
    'Beleza': const FaIcon(
      FontAwesomeIcons.paintbrush,
      color: Colors.white54,
    ),
    'Emergência': const FaIcon(
      FontAwesomeIcons.hospital,
      color: Colors.white54,
    ),
    'Reparos': const FaIcon(
      FontAwesomeIcons.hammer,
      color: Colors.white54,
    ),
    'Streaming': const FaIcon(
      FontAwesomeIcons.tv,
      color: Colors.white54,
    ),
    'Serviços': const FaIcon(
      FontAwesomeIcons.clipboard,
      color: Colors.white54,
    ),
    'Tecnologia': const FaIcon(
      FontAwesomeIcons.laptop,
      color: Colors.white54,
    ),
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
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: mediaQuery.size.width * 1,
              child: Container(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15),
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
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 8.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: IconButton(
                        onPressed: _showFilterOptions,
                        icon: Icon(Icons.filter_list),
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: availableHeight * 0.05,
            ),
            Container(
              height: availableHeight * 0.8,
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

                  List<DocumentSnapshot> transacoesList =
                      snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final tipo = data['tipo'];
                    return tipo != 'futura';
                  }).toList();

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
                      double transacaoValor = (data['valor'] ?? 0.0).toDouble();
                      String tipo = data['tipo'];
                      String categoria =
                          data['categoria'] ?? 'Categoria não especificada';
                      ;
                      String meioPagamento = data['meioPagamento'] ??
                          'Meio de pagamento não especificado';
                      Timestamp dateTimestamp = data['data'];
                      DateTime date = dateTimestamp.toDate();

                      FaIcon? categoryIcon = _categories[categoria.trim()];

                      if (categoryIcon == null) {
                        categoryIcon = const FaIcon(FontAwesomeIcons.question);
                      }

                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: ListTile(
                          onTap: () {
                            _showActionSheet(document);
                          },
                          leading: categoryIcon,
                          title: Text(
                            "$transacaoDescricao${tipo == 'gasto' ? ' - $meioPagamento' : ''}",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoria,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(241, 255, 255, 255)),
                              ),
                              Text(
                                DateFormat.yMMMMEEEEd('pt_BR').format(date),
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey.shade300),
                              ),
                            ],
                          ),
                          trailing: Text(
                            tipo == 'ganho'
                                ? "${currencyFormatter.format(transacaoValor)}"
                                : "-${currencyFormatter.format(transacaoValor)}",
                            style: TextStyle(
                              fontSize: 18,
                              color: tipo == 'ganho'
                                  ? Color.fromARGB(255, 90, 204, 94)
                                  : Color.fromARGB(255, 247, 88, 77),
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
