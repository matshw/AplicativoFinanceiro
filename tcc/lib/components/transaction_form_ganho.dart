import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TransactionForm extends StatefulWidget {
  final Function onSubmit;
  final ValueNotifier<Map<String, double>> balanceNotifier;

  const TransactionForm(this.onSubmit, this.balanceNotifier, {super.key});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
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
    double ganhoValue,
    double saldoValue,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    double currentGanhoValue = doc['ganhoValue'] ?? 0.0;
    double currentSaldoValue = doc['saldoValue'] ?? 0.0;
      await _firestore.collection('users').doc(uid).set({
        'ganhoValue': currentGanhoValue + ganhoValue,
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
        double ganhoValue = doc['ganhoValue'] ?? 0.0;
        double saldoValue = doc['saldoValue'] ?? 0.0;
        return {'ganhoValue': ganhoValue, 'saldoValue': saldoValue};
      } else {
        return {'ganhoValue': 0.0, 'saldoValue': 0.0};
      }
    } catch (e) {
      print("Erro ao obter informações: $e");
      return {'ganhoValue': 0.0, 'saldoValue': 0.0};
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

class _TransactionFormState extends State<TransactionForm> {
  double ganhoValue = 0;
  double saldoValue = 0;
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  bool imageExists = false;
  var _selectedDate = DateTime.now();
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedCategory;
  String? imageURL;

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

  void _submitForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("Erro: usuário não autenticado.");
      return;
    }

    final description = _descriptionController.text;
    final category = _selectedCategory;
    final value = double.tryParse(_valueController.text) ?? 0.0;

    if (description.isEmpty || value <= 0 || category == null) {
      _showError("Preencha todos os campos.");
      return;
    }

    double newSaldoValue = value;
    double newGanhoValue = value;

    try {
      await _firestoreService.addTransacao(user.uid, description, category,
          "ganho", value, _selectedDate, imageURL);
      await _firestoreService.updateInfo(
          user.uid, newGanhoValue, newSaldoValue);
      widget.balanceNotifier.value = {
        'ganhoValue': ganhoValue + newGanhoValue,
        'saldoValue': saldoValue + newSaldoValue,
      };
      Navigator.of(context).pop();
    } catch (e) {
      _showError("Erro ao adicionar transação.");
    }
  }

  final Map<String, FaIcon> _categories = {
    'Salário': const FaIcon(FontAwesomeIcons.sackDollar),
    'Freelance': const FaIcon(FontAwesomeIcons.briefcase),
    'Venda': const FaIcon(FontAwesomeIcons.circleDollarToSlot),
    'Comissão': const FaIcon(FontAwesomeIcons.handHoldingDollar),
    'Presente': const FaIcon(FontAwesomeIcons.gift),
    'Consultoria': const FaIcon(FontAwesomeIcons.magnifyingGlassDollar),
    'Outros': const FaIcon(FontAwesomeIcons.circleQuestion),
  };

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
        _chipSelection(category);
      },
    );
  }

  void _chipSelection(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _selectImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: ImageSource.gallery);

    if (file == null) {
      return;
    } else {
      try {
        String uniqueFileName =
            DateTime.now().millisecondsSinceEpoch.toString();

        Reference referenceRoot = FirebaseStorage.instance.ref();

        Reference referenceImageDirectory = referenceRoot.child('images');

        Reference referenceImageUploaded =
            referenceImageDirectory.child('$uniqueFileName.jpg');

        await referenceImageUploaded.putFile(File(file.path));
        String newImageURL = await referenceImageUploaded.getDownloadURL();
        setState(() {
          imageURL = newImageURL;
          imageExists = true;
        });
      } catch (e) {}
    }
  }

  void _showImagePopup() {
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
            content: Image.network(imageURL!),
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

  _showDatePicker() {
    showDatePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
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

  _updateDate() {
    setState(() {
      _selectedDate = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );
    });
    (_selectedDate) => _submitForm();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final avaliableHeight = mediaQuery.size.height - mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 248, 244),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Adicionar Ganho"),
        actions: [],
      ),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(top: avaliableHeight * 0.04),
            height: avaliableHeight * 0.9,
            child: Column(
              children: <Widget>[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Descrição",
                  ),
                ),
                TextField(
                  onSubmitted: (value) => _submitForm(),
                  controller: _descriptionController,
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
                  height: avaliableHeight * 0.05,
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Valor (R\$)"),
                ),
                TextField(
                  onSubmitted: (value) => _submitForm(),
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: "Valor R\$",
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 1.0,
                          )),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2.0,
                          ))),
                ),
                SizedBox(
                  height: avaliableHeight * 0.05,
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Categoria"),
                ),
                Wrap(
                  spacing: 8.0,
                  children: _categories.entries.map((entry) {
                    return FractionallySizedBox(
                        widthFactor: 1 / 3.5,
                        child: _createChip(entry.key, entry.value));
                  }).toList(),
                ),
                SizedBox(
                  height: avaliableHeight * 0.05,
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
                          onPressed: () async {
                            _selectImage();
                          },
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
                          onTap: () {
                            _showImagePopup();
                          },
                          child: const Text('Ver imagem anexada'),
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: avaliableHeight * 0.05,
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Data de recebimento")),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _updateDate();
                              });
                            },
                            child: const Text("Hoje"),
                          ),
                          TextButton(
                            onPressed: () {
                              _showDatePicker();
                            },
                            child: const Text("Passado"),
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
                      )),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitForm,
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
