import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tcc/screens/screen_categories.dart';
import 'package:tcc/screens/screen_payments.dart';

class TransactionFormAssinatura extends StatefulWidget {
  const TransactionFormAssinatura({Key? key}) : super(key: key);

  @override
  _TransactionFormAssinaturaState createState() =>
      _TransactionFormAssinaturaState();
}

class _TransactionFormAssinaturaState extends State<TransactionFormAssinatura>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  String? _selectedPaymentMethod;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  // Assinaturas Populares
  final List<Map<String, dynamic>> popularSubscriptions = [
    {
      'name': 'Amazon',
      'value': 29.90,
      'image': 'lib/assets/images/amazon_logo.png'
    },
    {
      'name': 'Netflix',
      'value': 39.90,
      'image': 'lib/assets/images/netflix_logo.png'
    },
    {
      'name': 'HBO Max',
      'value': 27.90,
      'image': 'lib/assets/images/disney_logo.png'
    },
    // Adicione outras assinaturas populares aqui
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _selectPaymentMethod() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectPaymentMethodScreen(
          onPaymentMethodSelected: (method, icon) {
            setState(() {
              _selectedPaymentMethod = method;
            });
          },
        ),
      ),
    );
  }

  void _selectCategory() {
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

  void _addPopularSubscription(Map<String, dynamic> subscription) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('assinaturas')
        .add({
      'nome': subscription['name'],
      'valor': subscription['value'],
      'periodo': 30, // período padrão para assinaturas populares
      'formaPagamento': 'Cartão de Crédito', // forma de pagamento padrão
      'categoria': 'Entretenimento', // categoria padrão
      'imagem': subscription['image'], // usa a imagem do popular
      'dataCriacao': Timestamp.now(),
    });

    Navigator.of(context).pop(); // Fecha a tela após adicionar
  }

  void _submitNewSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Validações básicas
    if (_nameController.text.isEmpty ||
        _valueController.text.isEmpty ||
        _periodController.text.isEmpty ||
        _selectedPaymentMethod == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    // Parse para valores numéricos
    double value = double.tryParse(_valueController.text) ?? 0.0;
    int period = int.tryParse(_periodController.text) ?? 0;

    // Salvar a nova assinatura no Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('assinaturas')
        .add({
      'nome': _nameController.text,
      'valor': value,
      'periodo': period,
      'formaPagamento': _selectedPaymentMethod,
      'categoria': _selectedCategory,
      'dataCriacao': Timestamp.now(),
    });

    // Limpar campos e fechar o formulário
    _nameController.clear();
    _valueController.clear();
    _periodController.clear();
    _selectedPaymentMethod = null;
    _selectedCategory = null;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height - mediaQuery.padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Adicionar Assinatura',
            style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          unselectedLabelColor: Colors.white,
          controller: _tabController,
          tabs: const [
            Tab(text: "Popular"),
            Tab(text: "Nova Assinatura"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView.builder(
            itemCount: popularSubscriptions.length,
            itemBuilder: (context, index) {
              final subscription = popularSubscriptions[index];
              return ListTile(
                leading: IconButton(
                  icon: Container(
                      width: 60.0, // Largura desejada
                      height: 60.0, // Altura desejada
                      child: Image.asset(
                        subscription['image'],
                      ) // Tamanho do ícone
                      ),
                  onPressed: () {
                    // Ação ao pressionar o botão
                  },
                ),
                title: Text(subscription['name'],
                    style: TextStyle(color: Colors.white)),
                subtitle: Text('R\$ ${subscription['value']}',
                    style: TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    // Adiciona a assinatura à lista
                    _submitNewSubscription();
                  },
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: availableHeight * 0.8,
                ),
                child: IntrinsicHeight(
                  child: Container(
                    padding: EdgeInsets.only(top: availableHeight * 0.025),
                    height: availableHeight * 0.7,
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Nome da assinatura",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                        ),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nome da assinatura',
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
                        const SizedBox(height: 20),
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
                          controller: _valueController,
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
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Período",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                        ),
                        TextField(
                          controller: _periodController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Periodo (dias)',
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
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Forma de pagamento",
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
                            _selectedPaymentMethod ??
                                "Selecionar Forma de Pagamento",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                          onTap: _selectPaymentMethod,
                        ),
                        const SizedBox(height: 20),
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
                          onTap: _selectCategory,
                        ),
                        const SizedBox(height: 20),
                        Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitNewSubscription,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  elevation: 5,
                                  fixedSize: Size.fromHeight(50),
                                ),
                                child: const Text(
                                  "Adicionar Assinatura",
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
