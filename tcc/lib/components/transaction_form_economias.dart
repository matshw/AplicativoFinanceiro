import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TransactionFormEconomias extends StatefulWidget {
  @override
  _TransactionFormEconomiasState createState() =>
      _TransactionFormEconomiasState();
}

class _TransactionFormEconomiasState extends State<TransactionFormEconomias> {
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _valorDesejadoController =
      TextEditingController();
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _addInvestment() async {
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double value = double.tryParse(_valorController.text) ?? 0.0;
    double valorDesejado =
        double.tryParse(_valorDesejadoController.text) ?? 0.0;
    String descricao = _descricaoController.text;

    if (value <= 0 ||
        valorDesejado <= 0 ||
        descricao.isEmpty ||
        _selectedImage == null) return;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userSnapshot = await userDoc.get();

    double totalEconomizado = 0.0;
    if (userSnapshot.exists && userSnapshot.data()!.containsKey('valorTotal')) {
      totalEconomizado = userSnapshot['valorTotal'];
    }

    await userDoc.collection('investments').add({
      'valor': value,
      'valorDesejado': valorDesejado,
      'descricao': descricao,
      'imagem': _selectedImage!.path,
      'data': _selectedDate,
      'historico': [
        {
          'tipo': 'Investido',
          'valor': value,
          'data': _selectedDate,
        }
      ],
    });

    await userDoc.update({
      'valorTotal': totalEconomizado + value,
    });

    _valorController.clear();
    _descricaoController.clear();
    _valorDesejadoController.clear();
    _selectedImage = null;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          'Adicionar economia',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
        child: Column(
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Objetivo",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                )),
            TextField(
              controller: _descricaoController,
              decoration: InputDecoration(
                labelText: 'Objetivo',
                labelStyle: TextStyle(color: Color.fromRGBO(158, 185, 211, 1)),
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
            SizedBox(height: 20),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Valor inicial (R\$)",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                )),
            TextField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'R\$ +',
                labelStyle: TextStyle(color: Color.fromRGBO(158, 185, 211, 1)),
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
            SizedBox(height: 20),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Valor desejado (R\$)",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                )),
            TextField(
                controller: _valorDesejadoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Meta (R\$)',
                  labelStyle:
                      TextStyle(color: Color.fromRGBO(158, 185, 211, 1)),
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
                )),
            SizedBox(height: 20),
            TextButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image, color: Colors.white),
              label: Text("Escolher Imagem",
                  style: TextStyle(color: Colors.white)),
            ),
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 100, width: 100),
            SizedBox(height: 20),
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                        elevation: 10,
                        fixedSize: Size.fromHeight(50)),
                    onPressed: _addInvestment,
                    child: const Text(
                      'Adicionar economia',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
