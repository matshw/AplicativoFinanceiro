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

class _TransactionFormGastoState extends State<TransactionFormGasto>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  bool imageExists = false;
  DateTime _selectedDate = DateTime.now();
  bool isParcelado = false;
  int? _selectedParcelas;
  String? _selectedCategory;
  String? _selectedPayment;
  String? imagem;
  int? _selectedPeriod;
  final List<int> periods = [15, 30, 60, 90];

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _submitFormGasto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("Erro: usuário não autenticado.");
      return;
    }

    final description = _descricaoController.text;
    final value = double.tryParse(_valorController.text) ?? 0.0;

    if (description.isEmpty ||
        value <= 0 ||
        _selectedCategory == null ||
        _selectedPayment == null) {
      _showError("Preencha todos os campos.");
      return;
    }

    if (_tabController.index == 1 && _selectedPeriod == null) {
      _showError("Selecione um período para o gasto recorrente.");
      return;
    }

    if (_tabController.index == 0) {
      await _addNormalTransaction(user.uid, description, value);
    } else {
      await _addRecurringTransaction(user.uid, description, value);
    }

    Navigator.of(context).pop();
  }

  Future<void> _addNormalTransaction(
      String uid, String description, double value) async {
    await _firestoreService.addTransacao(
      uid,
      description,
      _selectedCategory!,
      "gasto",
      value,
      _selectedDate,
      imagem,
      _selectedPayment!,
    );
  }

  Future<void> _addRecurringTransaction(
      String uid, String description, double value) async {
    await _firestoreService.addRecurringTransaction(
      uid,
      description,
      _selectedCategory!,
      "gasto_recorrente",
      value,
      _selectedPeriod!,
      _selectedDate,
      _selectedPayment!,
    );
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNormalTransactionForm() {
    return Column(
      children: [
        _buildDescriptionField(),
        _buildValueField(),
        _buildCategorySelector(),
        _buildPaymentMethodSelector(),
        _buildDateSelector(),
        _buildParceladoSwitch(),
        _buildImageSelector(),
        _buildSubmitButton("Adicionar gasto"),
      ],
    );
  }

  Widget _buildRecurringTransactionForm() {
    return Column(
      children: [
        _buildDescriptionField(),
        _buildValueField(),
        DropdownButton<int>(
          value: _selectedPeriod,
          hint: const Text("Selecionar período de recorrência"),
          items: periods.map((int days) {
            return DropdownMenuItem<int>(
              value: days,
              child: Text("$days dias"),
            );
          }).toList(),
          onChanged: (int? value) {
            setState(() {
              _selectedPeriod = value;
            });
          },
        ),
        _buildCategorySelector(),
        _buildPaymentMethodSelector(),
        _buildImageSelector(),
        _buildSubmitButton("Adicionar gasto recorrente"),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descricaoController,
      decoration: InputDecoration(
        labelText: 'Descrição',
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
    );
  }

  Widget _buildValueField() {
    return TextField(
      controller: _valorController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Valor (R\$)',
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
    );
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
          onPaymentMethodSelected: (payment, icon) {
            setState(() {
              _selectedPayment = payment;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return ListTile(
      leading: Icon(Icons.category, color: Colors.white),
      title: Text(
        _selectedCategory ?? "Selecionar Categoria",
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      onTap: () {
        _openCategorySelection();
      },
    );
  }

  Widget _buildPaymentMethodSelector() {
    return ListTile(
      leading: Icon(Icons.credit_card, color: Colors.white),
      title: Text(
        _selectedPayment ?? "Selecionar Forma de Pagamento",
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      onTap: () {
        _openPaymentMethodSelection();
      },
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            TextButton(
              onPressed: _selectToday,
              child: const Text("Hoje",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ),
            TextButton(
              onPressed: _selectDate,
              child: const Text("Em Breve",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
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
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildParceladoSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Parcelado",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white)),
        Switch(
          activeColor: Colors.green,
          value: isParcelado,
          onChanged: (bool newValue) {
            setState(() {
              isParcelado = newValue;
              if (!isParcelado) _selectedParcelas = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildImageSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const FaIcon(FontAwesomeIcons.solidImage, color: Colors.white),
        MaterialButton(
          onPressed: _selectImage,
          child: const Text("Anexar imagem",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
        ),
        if (imageExists)
          FittedBox(
            child: InkWell(
              onTap: _showImagePopup,
              child: const Text('Ver imagem anexada'),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(String label) {
    return ElevatedButton(
      onPressed: _submitFormGasto,
      child: Text(label),
    );
  }

  void _selectToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  void _selectDate() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    ).then((pickedDate) {
      if (pickedDate != null) {
        setState(() {
          _selectedDate = pickedDate;
        });
      }
    });
  }

  void _selectImage() async {
    final imagePicker = ImagePicker();
    final file = await imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
    final referenceRoot = FirebaseStorage.instance.ref();
    final referenceImageDirectory = referenceRoot.child('images');
    final referenceImageUploaded =
        referenceImageDirectory.child('$uniqueFileName.jpg');

    await referenceImageUploaded.putFile(File(file.path));
    final newImageURL = await referenceImageUploaded.getDownloadURL();
    setState(() {
      imagem = newImageURL;
      imageExists = true;
    });
  }

  void _showImagePopup() {
    if (imagem == null) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Image.network(imagem!),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adicionar Gasto"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Gasto Normal"),
            Tab(text: "Gasto Recorrente"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNormalTransactionForm(),
          _buildRecurringTransactionForm(),
        ],
      ),
    );
  }
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
    } catch (e) {
      print("Erro ao adicionar transação: $e");
    }
  }

  Future<void> addRecurringTransaction(
    String uid,
    String descricao,
    String categoria,
    String tipo,
    double valor,
    int periodo,
    DateTime dataInicial,
    String meioPagamento,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('recurring_transactions')
          .add({
        'descricao': descricao,
        'valor': valor,
        'categoria': categoria,
        'tipo': tipo,
        'periodo': periodo,
        'dataInicial': dataInicial,
        'meioPagamento': meioPagamento,
      });
    } catch (e) {
      print("Erro ao adicionar transação recorrente: $e");
    }
  }
}
