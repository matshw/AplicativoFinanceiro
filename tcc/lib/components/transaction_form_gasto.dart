import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class TransactionFormGasto extends StatefulWidget {
  final ValueNotifier<Map<String, double>> balanceNotifier;
  final Function onSubmit;
  const TransactionFormGasto(this.balanceNotifier, this.onSubmit, {super.key});

  @override
  State<TransactionFormGasto> createState() => _TransactionFormGastoState();
}

class FirestoreService {
  final CollectionReference gastos =
      FirebaseFirestore.instance.collection('gastos');

  Future<void> addGasto(
    String descricao,
    double valor,
    String categoria,
    DateTime dataPagamento,
    String? imagem,
  ) async {
    try {
      await gastos.add({
        'descricao': descricao,
        'valor': valor,
        'categoria': categoria,
        'dataPagamento': dataPagamento,
        'imagem': imagem ?? '',
      });
      print("Gasto adicionado com sucesso.");
    } catch (e) {
      print("Erro ao adicionar gasto: $e");
    }
  }

  final DocumentReference userInfo =
      FirebaseFirestore.instance.collection('userInfo').doc('user_info');

  Future<void> updateInfo(
    double gastoValue,
    double saldoValue,
  ) async {
    try {
      await userInfo.set({
        'gastoValue': gastoValue,
        'saldoValue': saldoValue,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating info: $e");
    }
  }

  Future<Map<String, double>> getInfo() async {
    try {
      DocumentSnapshot doc = await userInfo.get();
      if (doc.exists) {
        double gastoValue = doc['gastoValue'] ?? 0.0;
        double saldoValue = doc['saldoValue'] ?? 0.0;
        return {'gastoValue': gastoValue, 'saldoValue': saldoValue};
      } else {
        return {'gastoValue': 0.0, 'saldoValue': 0.0};
      }
    } catch (e) {
      print("Error fetching info: $e");
      return {'gastoValue': 0.0, 'saldoValue': 0.0};
    }
  }
}

class _TransactionFormGastoState extends State<TransactionFormGasto> {
  double gastoValue = 0;
  double saldoValue = 0;
  bool imageExists = false;
  DateTime dataPagamento = DateTime.now();

  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedCategory;
  String? _selectedPayment;
  String? imagem;
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();

  Future<void> _loadInfo() async {
    Map<String, double> info = await _firestoreService.getInfo();
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
    final descricao = _descricaoController.text;
    final valor = double.tryParse(_valorController.text) ?? 0.0;
    final categoria = _selectedCategory;
    final pagamento = _selectedPayment;

    if (descricao.isEmpty) {
      _showError("Descrição não pode estar vazia.");
      return;
    }
    if (valor <= 0) {
      _showError("Valor deve ser maior que zero.");
      return;
    }
    if (categoria == null) {
      _showError("Categoria não selecionada.");
      return;
    }

    if (pagamento == null) {
      _showError("Modo de pagamento não selecionado.");
      return;
    }

    gastoValue += valor;
    saldoValue = saldoValue - valor;

    try {
      await FirestoreService().addGasto(
        descricao,
        valor,
        categoria,
        dataPagamento,
        imagem,
      );
      await _firestoreService.updateInfo(gastoValue, saldoValue);
      widget.balanceNotifier.value = {
        'gastoValue': gastoValue,
        'saldoValue': saldoValue,
      };
      Navigator.of(context).pop();
    } catch (e) {
      print("Error submitting form: $e");
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

  final Map<String, FaIcon> _payMode = {
    'Dinheiro': const FaIcon(FontAwesomeIcons.moneyBill),
    'Cartão de Débito': const FaIcon(FontAwesomeIcons.creditCard),
    'Cartão de Crédito': const FaIcon(FontAwesomeIcons.ccVisa),
  };

  void _chipSelectionPayment(String payment) {
    setState(() {
      _selectedPayment = payment;
    });
  }

  Widget _createChipPayment(String payment, FaIcon icon) {
    return ChoiceChip(
      shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: Colors.blue,
          ),
          borderRadius: BorderRadius.circular(8.0)),
      selected: _selectedPayment == payment,
      avatar: icon,
      label: FittedBox(child: Text(payment)),
      backgroundColor: const Color.fromRGBO(178, 219, 255, 1),
      selectedColor: Colors.blue,
      onSelected: (selected) {
        if (selected) {
          _chipSelectionPayment(payment);
        }
      },
    );
  }

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
          dataPagamento = pickedDate;
        });
      }
    });
  }

  _updateDate() {
    setState(() {
      dataPagamento = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );
    });
    (dataPagamento) => _submitFormGasto();
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
        title: Text("Adicionar gasto"),
        backgroundColor: Colors.blue,
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(top: avaliableHeight * 0.025),
            height: avaliableHeight,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Descrição"),
                ),
                TextField(
                  controller: _descricaoController,
                  onSubmitted: (value) => _submitFormGasto,
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
                  onSubmitted: (value) => _submitFormGasto,
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Modo de pagamento"),
                ),
                Wrap(
                  spacing: 4.0,
                  children: _payMode.entries.map((entry) {
                    return FractionallySizedBox(
                      widthFactor: 1 / 3.2,
                      child: _createChipPayment(entry.key, entry.value),
                    );
                  }).toList(),
                ),
                SizedBox(
                  height: avaliableHeight * 0.02,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Data do pagamento"),
                ),
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
                            onPressed: _showDatePicker,
                            child: const Text("Em Breve"),
                          ),
                        ],
                      ),
                      // SizedBox(
                      //   width: 40,
                      // ),
                      FittedBox(
                          child: Text(
                        (dataPagamento.year == DateTime.now().year &&
                                dataPagamento.month == DateTime.now().month &&
                                dataPagamento.day == DateTime.now().day)
                            ? 'Hoje'
                            : 'Data Selecionada: ${DateFormat('d/MMM/y', 'pt_BR').format(dataPagamento)}',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      )),
                    ],
                  ),
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
