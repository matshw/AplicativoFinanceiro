import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tcc/utils/firestore_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tcc/screens/screen_categories.dart'; // Importa a tela de seleção de categoria

class TransactionForm extends StatefulWidget {
  final Function onSubmit;
  final ValueNotifier<Map<String, double>> balanceNotifier;

  const TransactionForm(this.onSubmit, this.balanceNotifier, {super.key});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
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

  Future<void> _submitForm() async {
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

      setState(() {
        ganhoValue += newGanhoValue;
        saldoValue += newSaldoValue;
      });

      widget.balanceNotifier.value = {
        'ganhoValue': ganhoValue,
        'saldoValue': saldoValue,
      };

      Navigator.of(context).pop();
    } catch (e) {
      _showError("Erro ao adicionar transação de ganho.");
    }
  }

  Future<void> _selectImage() async {
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
      } catch (e) {
        _showError("Erro ao carregar imagem.");
      }
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

  void _showDatePicker() {
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

  void _openCategorySelection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectCategoryScreen(
          onCategorySelected: (category, icon) {
            setState(() {
              _selectedCategory = category;
            });
          },
        ),
      ),
    );
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
                  child: Text("Descrição"),
                ),
                TextField(
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
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: avaliableHeight * 0.05),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Valor (R\$)"),
                ),
                TextField(
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
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: avaliableHeight * 0.05),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Categoria"),
                ),
                ListTile(
                  leading: Icon(Icons.category),
                  title: Text(_selectedCategory ?? "Selecionar Categoria"),
                  onTap: _openCategorySelection,
                ),
                SizedBox(height: avaliableHeight * 0.05),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Data de recebimento"),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _showDatePicker,
                    ),
                  ],
                ),
                SizedBox(height: avaliableHeight * 0.05),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.image,
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
                    if (imageExists)
                      TextButton(
                        onPressed: _showImagePopup,
                        child: const Text(
                          "Ver imagem",
                          style: TextStyle(color: Colors.blue),
                        ),
                      )
                    else
                      const Text(
                        "Nenhuma imagem selecionada",
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
                SizedBox(height: avaliableHeight * 0.05),
                Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text("Adicionar"),
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
