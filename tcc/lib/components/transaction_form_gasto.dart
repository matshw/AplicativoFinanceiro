import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
      });
    } catch (e) {
      print("Erro ao adicionar transação: $e");
    }
  }

  Future<void> updateInfo(
    String uid,
    double gastoValue,
    double saldoValue,
  ) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      double currentGastoValue = doc['gastoValue'] ?? 0.0;
      double currentSaldoValue = doc['saldoValue'] ?? 0.0;
      await _firestore.collection('users').doc(uid).set({
        'gastoValue': currentGastoValue + gastoValue,
        'saldoValue': currentSaldoValue + saldoValue,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Erro ao atualizar informações: $e");
    }
  }

  Future<Map<String, double>> getInfo(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        double gastoValue = doc['gastoValue'] ?? 0.0;
        double saldoValue = doc['saldoValue'] ?? 0.0;
        return {'gastoValue': gastoValue, 'saldoValue': saldoValue};
      } else {
        return {'gastoValue': 0.0, 'saldoValue': 0.0};
      }
    } catch (e) {
      print("Erro ao obter informações: $e");
      return {'gastoValue': 0.0, 'saldoValue': 0.0};
    }
  }

  Stream<QuerySnapshot> getTransactionsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transacao')
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

  void _submitFormGasto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("Erro: usuário não autenticado.");
      return;
    }

    final description = _descricaoController.text;
    final category = _selectedCategory;
    final value = double.tryParse(_valorController.text) ?? 0.0;

    if (description.isEmpty || value <= 0 || category == null) {
      _showError("Preencha todos os campos.");
      return;
    }

    double newSaldoValue = -value;
    double newGastoValue = value;
    try {
      await _firestoreService.addTransacao(user.uid, description, category,
          "gasto", value, _selectedDate, imagem);
      await _firestoreService.updateInfo(
          user.uid, newGastoValue, newSaldoValue);
      widget.balanceNotifier.value = {
        'gastoValue': gastoValue,
        'saldoValue': saldoValue
      };
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

  void _chipSelection(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  Widget _createChip(String category, FaIcon icon) {
    return ChoiceChip(
      shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: Colors.blue,
          ),
          borderRadius: BorderRadius.circular(8.0)),
      selected: _selectedCategory == category,
      avatar: icon,
      label: FittedBox(child: Text(category)),
      backgroundColor: const Color.fromRGBO(178, 219, 255, 1),
      selectedColor: Colors.blue,
      onSelected: (selected) {
        if (selected) {
          _chipSelection(category);
        }
      },
    );
  }

  void _selectImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: ImageSource.gallery);

    if (file == null) {
      print("Nenhuma imagem selecionada.");
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
      print("Imagem carregada com sucesso: $newImageURL");
    } catch (e) {
      print("Erro ao carregar imagem: $e");
    }
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
      backgroundColor: const Color.fromARGB(255, 230, 248, 244),
      appBar: AppBar(
        title: const Text("Adicionar gasto"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(top: avaliableHeight * 0.025),
            height: avaliableHeight,
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Descrição"),
                ),
                TextField(
                  controller: _descricaoController,
                  onSubmitted: (value) => _submitFormGasto(),
                  decoration: InputDecoration(
                      labelText: "Descrição",
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 1.0,
                          )),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2.0,
                          ))),
                ),
                SizedBox(
                  height: avaliableWidth * 0.03,
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Valor (R\$)"),
                ),
                TextField(
                  controller: _valorController,
                  onSubmitted: (value) => _submitFormGasto(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: "Valor R\$",
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 1.0,
                          )),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2.0,
                          ))),
                ),
                SizedBox(
                  height: avaliableWidth * 0.05,
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Categoria"),
                ),
                Wrap(
                  spacing: 5.0,
                  children: _categories.entries.map((entry) {
                    return FractionallySizedBox(
                        widthFactor: 1 / 3.5,
                        child: _createChip(entry.key, entry.value));
                  }).toList(),
                ),
                SizedBox(
                  height: avaliableHeight * 0.02,
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Data do pagamento"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        TextButton(
                          onPressed: _updateDate,
                          child: const Text("Hoje"),
                        ),
                        TextButton(
                          onPressed: _showDatePicker,
                          child: const Text("Em Breve"),
                        ),
                      ],
                    ),
                    FittedBox(
                      child: Text(
                        (_selectedDate.year == DateTime.now().year &&
                                _selectedDate.month == DateTime.now().month &&
                                _selectedDate.day == DateTime.now().day)
                            ? 'Hoje'
                            : 'Data Selecionada: ${DateFormat('d/MMM/y', 'pt_BR').format(_selectedDate)}',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.solidImage,
                          color: Colors.blue,
                        ),
                        MaterialButton(
                          onPressed: _selectImage,
                          child: const Text(
                            "Anexar imagem",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    if (!imageExists)
                      const Text(
                        "Nenhuma imagem selecionada",
                        style: TextStyle(fontSize: 12),
                      )
                    else
                      FittedBox(
                        child: InkWell(
                          onTap: _showImagePopup,
                          child: const Text('Ver imagem anexada'),
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: avaliableHeight * 0.02,
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitFormGasto,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue),
                        child: const Text(
                          "Nova transação",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
