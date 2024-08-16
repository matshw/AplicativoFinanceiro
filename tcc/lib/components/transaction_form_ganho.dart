import 'dart:io';
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
  final CollectionReference ganhos =
      FirebaseFirestore.instance.collection('ganhos');

  Future<void> addGanho(
    String descricao,
    String categoria,
    double valor,
    DateTime dataRecebimento,
    String? imagem,
  ) async {
    try {
      await ganhos.add({
        'descricao': descricao,
        'categoria': categoria,
        'valor': valor,
        'dataRecebimento': dataRecebimento,
        'imagem': imagem ?? '',
      });
    } catch (e) {}
  }

  final DocumentReference userInfo =
      FirebaseFirestore.instance.collection('userInfo').doc('user_info');

  Future<void> updateInfo(
    double ganhoValue,
    double saldoValue,
  ) async {
    try {
      await userInfo.set({
        'ganhoValue': ganhoValue,
        'saldoValue': saldoValue,
      }, SetOptions(merge: true));
    } catch (e) {}
  }

  Future<Map<String, double>> getInfo() async {
    try {
      DocumentSnapshot doc = await userInfo.get();
      if (doc.exists) {
        double ganhoValue = doc['ganhoValue'] ?? 0.0;
        double saldoValue = doc['saldoValue'] ?? 0.0;
        return {'ganhoValue': ganhoValue, 'saldoValue': saldoValue};
      } else {
        return {'ganhoValue': 0.0, 'saldoValue': 0.0};
      }
    } catch (e) {
      return {'ganhoValue': 0.0, 'saldoValue': 0.0};
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
  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    Map<String, double> info = await _firestoreService.getInfo();
    setState(() {
      ganhoValue = info['ganhoValue']!;
      saldoValue = info['saldoValue']!;
    });
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

  void _submitForm() async {
    final description = _descriptionController.text;
    final category = _selectedCategory;

    final value = double.tryParse(_valueController.text) ?? 0.0;

    if (description.isEmpty) {
      _showError("Descrição não pode estar vazia.");
      return;
    }
    if (value <= 0) {
      _showError("Valor deve ser maior que zero.");
      return;
    }
    if (category == null) {
      _showError("Categoria não selecionada.");
      return;
    }
    ganhoValue = ganhoValue + value;
    saldoValue = saldoValue + value;
    try {
      await FirestoreService()
          .addGanho(description, category, value, _selectedDate, imageURL);
      await FirestoreService().updateInfo(ganhoValue, saldoValue);
      widget.balanceNotifier.value = {
        'ganhoValue': ganhoValue,
        'saldoValue': saldoValue,
      };
      Navigator.of(context).pop();
    } catch (e) {
      print("erro ${e}");
      _showError("Erro ao adicionar transação");
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
                  onSubmitted: (value) => _submitForm,
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
                  onSubmitted: (value) => _submitForm,
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
                    if (imageExists == false)
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
