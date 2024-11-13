import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tcc/screens/screen_categories_gasto.dart';
import 'package:tcc/screens/screen_payments.dart';

class TransactionFormGasto extends StatefulWidget {
  final ValueNotifier<Map<String, double>> balanceNotifier;
  final Function onSubmit;
  const TransactionFormGasto(this.balanceNotifier, this.onSubmit);

  @override
  State<TransactionFormGasto> createState() => _TransactionFormGastoState();
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTransacao(
    String uid,
    String descricao,
    String categoria,
    String tipo,
    double valor,
    DateTime data,
    String? imagem,
    String meioPagamento,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('transacao')
          .add({
        'descricao': descricao,
        'categoria': categoria,
        'tipo': tipo,
        'valor': valor,
        'data': data,
        'imagem': imagem ?? '',
        'meioPagamento': meioPagamento,
      });
    } catch (e) {}
  }

  Future<void> updateInfo(
    String uid,
    double valor,
    double saldoValue,
    String tipo,
  ) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      double currentGanhoValue = _getDoubleValue(doc['ganhoValue']);
      double currentGastoValue = _getDoubleValue(doc['gastoValue']);
      double currentSaldoValue = _getDoubleValue(doc['saldoValue']);
      if (tipo == 'ganho') {
        await _firestore.collection('users').doc(uid).update({
          'ganhoValue': currentGanhoValue + valor,
          'saldoValue': currentSaldoValue + saldoValue,
        });
      } else if (tipo == 'gasto') {
        await _firestore.collection('users').doc(uid).update({
          'gastoValue': currentGastoValue + valor,
          'saldoValue': currentSaldoValue + saldoValue,
        });
      }
    } catch (e) {}
  }

  Future<Map<String, double>> getInfo(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        double gastoValue = _getDoubleValue(doc['gastoValue']);
        double saldoValue = _getDoubleValue(doc['saldoValue']);
        return {'gastoValue': gastoValue, 'saldoValue': saldoValue};
      } else {
        return {'gastoValue': 0.0, 'saldoValue': 0.0};
      }
    } catch (e) {
      return {'gastoValue': 0.0, 'saldoValue': 0.0};
    }
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

  Stream<QuerySnapshot> getFutureTransactionsStream(String uid) {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transacao')
        .where('data', isGreaterThanOrEqualTo: startOfMonth)
        .where('data', isLessThanOrEqualTo: endOfMonth)
        .where('tipo', isEqualTo: 'futura')
        .orderBy('data', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getSaldoStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
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
      double oldValor = _getDoubleValue(docSnapshot['valor']);
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

  Future<void> removeTransacao(String uid, String docID, double valor,
      String tipo, DateTime data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('transacao')
        .doc(docID)
        .delete();

    bool isFutureTransaction = data.isAfter(DateTime.now());

    if (!isFutureTransaction) {
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
  }
}

class _TransactionFormGastoState extends State<TransactionFormGasto> {
  double gastoValue = 0;
  double saldoValue = 0;
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  bool imageExists = false;
  var _selectedDate = DateTime.now();
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedCategory;
  String? _selectedPayment;
  String? imagem;
  FaIcon defaultIcon = FaIcon(FontAwesomeIcons.question);
  bool isRecorrente = false;
  int? _recorrenciaPeriod;
  bool isParcelado = false;
  int? _selectedParcelas;
  bool isParcelasEnabled = true;
  bool isRecorrenteEnabled = true;

  Stream<QuerySnapshot> _getFutureTransactionsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }
    return _firestoreService.getFutureTransactionsStream(user.uid);
  }

  // Função que carrega informações do saldo e gasto
  Future<void> _loadInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    Map<String, double> info = await _firestoreService.getInfo(user.uid);
    setState(() {
      gastoValue = info['gastoValue']!;
      saldoValue = info['saldoValue']!;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  void _openCategorySelection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectGastoCategoryScreen(
          onCategorySelected: (category, icon) {
            setState(() {
              _selectedCategory = category;
            });
          },
        ),
      ),
    );
  }

  void _openPaymentMethodSelection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectPaymentMethodScreen(
          onPaymentMethodSelected: (method, icon) {
            setState(() {
              _selectedPayment = method;
            });
          },
        ),
      ),
    );
  }

  // Função para processar as transações futuras
  void _processarTransacoesFuturas() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _getFutureTransactionsStream().listen((snapshot) {
      for (var doc in snapshot.docs) {
        var data = doc['data'].toDate();
        var tipo = doc['tipo'];
        var valor = doc['valor'];
        var descricao = doc['descricao'];

        if (tipo == 'futura' &&
            (data.isBefore(DateTime.now()) ||
                data.isAtSameMomentAs(DateTime.now()))) {
          _firestoreService.updateTransacao(
            user.uid,
            doc.id,
            descricao,
            valor,
            "gasto",
          );

          _firestoreService.updateInfo(
            user.uid,
            valor,
            -valor,
            'gasto',
          );
        }
      }
    });
  }

  // Função para exibir um popup para selecionar o número de parcelas
  void _showParcelasPopup() {
    showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecione o número de parcelas'),
        content: SingleChildScrollView(
          child: Column(
            children: List.generate(12, (index) {
              int value = index + 1;
              return ListTile(
                title: Text("$value Parcelas"),
                onTap: () {
                  setState(() {
                    _selectedParcelas = value;
                  });
                  Navigator.of(context).pop();
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  // Função para exibir um popup para selecionar o período de recorrência
  void _showRecorrenciaPopup() {
    showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecione o período de recorrência'),
        content: SingleChildScrollView(
          child: Column(
            children: [15, 30, 60, 90].map((value) {
              return ListTile(
                title: Text("$value dias"),
                onTap: () {
                  setState(() {
                    _recorrenciaPeriod = value;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
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

  void _submitFormGasto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("Erro: usuário não autenticado.");
      return;
    }

    final description = _descricaoController.text;
    final category = _selectedCategory;
    final meioPagamento = _selectedPayment;
    final value = _getDoubleValue(double.tryParse(_valorController.text));

    if (description.isEmpty ||
        value <= 0 ||
        category == null ||
        meioPagamento == null) {
      _showError("Preencha todos os campos.");
      return;
    }

    bool isFutureTransaction = _selectedDate.isAfter(DateTime.now());

    try {
      if (isParcelado && _selectedParcelas != null && _selectedParcelas! > 1) {
        double parcelaValue = value / _selectedParcelas!;
        DateTime currentDate = _selectedDate;

        for (int i = 0; i < _selectedParcelas!; i++) {
          await _firestoreService.addTransacao(
            user.uid,
            "$description (Parcela ${i + 1}/$_selectedParcelas)",
            category,
            "futura",
            parcelaValue,
            currentDate,
            imagem,
            meioPagamento,
          );

          currentDate = DateTime(
              currentDate.year, currentDate.month + 1, currentDate.day);
        }
      } else if (isRecorrente && _recorrenciaPeriod != null) {
        DateTime currentDate = _selectedDate;
        for (int i = 0; i < 12; i++) {
          await _firestoreService.addTransacao(
            user.uid,
            "$description (Recorrente)",
            category,
            "futura",
            value,
            currentDate,
            imagem,
            meioPagamento,
          );
          currentDate = DateTime(currentDate.year,
              currentDate.month + _recorrenciaPeriod!, currentDate.day);
        }
      } else {
        await _firestoreService.addTransacao(
          user.uid,
          description,
          category,
          isFutureTransaction ? "futura" : "gasto",
          value,
          _selectedDate,
          imagem,
          meioPagamento,
        );

        if (!isFutureTransaction) {
          await _firestoreService.updateInfo(
            user.uid,
            value,
            -value,
            'gasto',
          );

          setState(() {
            gastoValue += value;
            saldoValue -= value;
          });

          widget.balanceNotifier.value = {
            'gastoValue': gastoValue,
            'saldoValue': saldoValue,
          };
        }
      }

      Navigator.of(context).pop();
    } catch (e) {
      _showError("Erro ao adicionar transação.");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Erro"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  final Map<String, FaIcon> _paymentMethods = {
    "Dinheiro": const FaIcon(FontAwesomeIcons.moneyBill),
    "Cartão de Crédito": const FaIcon(FontAwesomeIcons.ccVisa),
    "Cartão de Débito": const FaIcon(FontAwesomeIcons.ccMastercard),
    "Transferência Bancária": const FaIcon(FontAwesomeIcons.moneyBillTransfer),
    "Pix": const FaIcon(FontAwesomeIcons.pix),
    "Boleto": const FaIcon(FontAwesomeIcons.file),
  };

  final Map<String, FaIcon> _categories = {
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

  void _selectImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: ImageSource.gallery);

    if (file == null) {
      return;
    }

    try {
      String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference referenceRoot = FirebaseStorage.instance.ref();
      Reference referenceImageDirectory = referenceRoot.child('images');
      Reference referenceImageUploaded =
          referenceImageDirectory.child('$uniqueFileName.jpg');

      await referenceImageUploaded.putFile(File(file.path));
      String newImageURL = await referenceImageUploaded.getDownloadURL();
      setState(() {
        imagem = newImageURL;
        imageExists = true;
      });
    } catch (e) {}
  }

  void _showImagePopup() {
    if (imagem == null) return;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              "Imagem anexada",
              style: TextStyle(
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            content: Image.network(imagem!),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Fechar"))
            ],
          );
        });
  }

  void _showDatePicker() {
    showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
            locale: const Locale('pt', 'BR'))
        .then((pickedDate) {
      if (pickedDate == null) {
        return;
      } else {
        setState(() {
          _selectedDate = pickedDate;
        });
      }
    });
  }

  void _updateDate() {
    setState(() {
      _selectedDate = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final avaliableHeight = mediaQuery.size.height - mediaQuery.padding.top;
    final avaliableWidth = mediaQuery.size.width;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          "Adicionar gasto",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Container(
            height: avaliableHeight * 0.9,
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Descrição",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ),
                      TextField(
                        controller: _descricaoController,
                        decoration: InputDecoration(
                          labelText: 'Descrição',
                          labelStyle: TextStyle(
                              color: Color.fromRGBO(158, 185, 211, 1)),
                          fillColor: Theme.of(context).colorScheme.tertiary,
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: avaliableWidth * 0.02,
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Valor (R\$)",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ),
                      TextField(
                        controller: _valorController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Valor R\$',
                          labelStyle: TextStyle(
                              color: Color.fromRGBO(158, 185, 211, 1)),
                          fillColor: Theme.of(context).colorScheme.tertiary,
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: avaliableHeight * 0.02,
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Categoria",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.category,
                          color: Colors.white,
                        ),
                        title: Text(
                          _selectedCategory ?? "Selecionar Categoria",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                        onTap: _openCategorySelection,
                      ),
                      SizedBox(
                        height: avaliableHeight * 0.02,
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Meio de pagamento",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.credit_card,
                          color: Colors.white,
                        ),
                        title: Text(
                          _selectedPayment ?? "Selecionar Meio de Pagamento",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                        onTap: _openPaymentMethodSelection,
                      ),
                      SizedBox(
                        height: avaliableHeight * 0.02,
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Data do pagamento",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              TextButton(
                                onPressed: _updateDate,
                                child: const Text(
                                  "Hoje",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white),
                                ),
                              ),
                              TextButton(
                                onPressed: _showDatePicker,
                                child: const Text(
                                  "Em Breve",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          FittedBox(
                            child: Text(
                              (_selectedDate.year == DateTime.now().year &&
                                      _selectedDate.month ==
                                          DateTime.now().month &&
                                      _selectedDate.day == DateTime.now().day)
                                  ? 'Hoje'
                                  : 'Data Selecionada: ${DateFormat('d/MMM/y', 'pt_BR').format(_selectedDate)}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: avaliableHeight * 0.02,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Parcelado",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                          Switch(
                            activeColor: Colors.green,
                            value: isParcelado,
                            onChanged: (bool newValue) {
                              setState(() {
                                isParcelado = newValue;

                                if (isParcelado) {
                                  _recorrenciaPeriod = null;
                                  isRecorrente = false;
                                  isRecorrenteEnabled = false;
                                  _showParcelasPopup();
                                } else {
                                  _selectedParcelas = null;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (_selectedParcelas != null)
                        Text(
                          "Parcelas selecionadas: $_selectedParcelas",
                          style: TextStyle(color: Colors.white),
                        ),
                      SizedBox(
                        height: avaliableHeight * 0.02,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Gasto Recorrente",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                          Switch(
                            activeColor: Colors.green,
                            value: isRecorrente,
                            onChanged: (bool newValue) {
                              setState(() {
                                isRecorrente = newValue;

                                if (isRecorrente) {
                                  _selectedParcelas = null;
                                  isParcelado = false;
                                  isParcelasEnabled = false;
                                  _showRecorrenciaPopup();
                                } else {
                                  _recorrenciaPeriod = null;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (_recorrenciaPeriod != null)
                        Text(
                          "Período de recorrência: $_recorrenciaPeriod dias",
                          style: TextStyle(color: Colors.white),
                        ),
                      SizedBox(
                        height: avaliableHeight * 0.02,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Column(
                                children: [],
                              ),
                              const FaIcon(
                                FontAwesomeIcons.solidImage,
                                color: Colors.white,
                              ),
                              MaterialButton(
                                onPressed: _selectImage,
                                child: const Text(
                                  "Anexar imagem",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          if (imageExists)
                            FittedBox(
                              child: InkWell(
                                onTap: _showImagePopup,
                                child: const Text('Ver imagem anexada'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  child: Container(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                        elevation: 10,
                      ),
                      onPressed: _submitFormGasto,
                      child: const Text(
                        "Adicionar gasto",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
