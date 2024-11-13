import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcc/components/card_balance.dart';
import 'package:tcc/components/transaction_form_economias.dart';
import 'package:tcc/components/transaction_form_ganho.dart';
import 'package:tcc/components/transaction_form_gasto.dart';
import 'package:tcc/components/transaction_list.dart';
import 'package:tcc/components/transaction_list_future.dart';
import 'dart:io';
import 'screen_infos.dart';

class ScreenMain extends StatefulWidget {
  const ScreenMain({Key? key}) : super(key: key);

  @override
  State<ScreenMain> createState() => _ScreenMainState();
}

class _ScreenMainState extends State<ScreenMain> {
  String _userName = 'Nome do Usuário';

  final ValueNotifier<Map<String, double>> balanceNotifier =
      ValueNotifier({'ganhoValue': 0.0, 'saldoValue': 0.0, 'gastoValue': 0.0});

  void _addTransacao(
      String descricao,
      String categoria,
      String tipo,
      double valor,
      DateTime dataRecebimento,
      String? imagem,
      String meioPagamento) {
    setState(() {
      if (tipo == 'ganho') {
        _updateBalanceGanho(valor);
      } else if (tipo == 'gasto') {
        _updateBalanceGasto(valor);
      }
    });
  }

  void _updateBalanceGanho(double value) {
    balanceNotifier.value = {
      'ganhoValue': balanceNotifier.value['ganhoValue']! + value,
      'saldoValue': balanceNotifier.value['saldoValue']! + value,
      'gastoValue': balanceNotifier.value['gastoValue']!,
    };
  }

  void _updateBalanceGasto(double value) {
    balanceNotifier.value = {
      'gastoValue': balanceNotifier.value['gastoValue']! + value,
      'saldoValue': balanceNotifier.value['saldoValue']! - value,
      'ganhoValue': balanceNotifier.value['ganhoValue']!,
    };
  }

  void _openTransactionFormModalCofrinho() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionFormEconomias(),
      ),
    );
  }

  void _openTransactionFormModalGanho() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TransactionForm(_addTransacao, balanceNotifier);
      },
    );
  }
void _openPersonalInfoScreen() async {
  final newName = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => PersonalInfoScreen(),
    ),
  );
  if (newName != null) {
    _updateUserName(newName);
  }
}
  void _openTransactionFormModalGasto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TransactionFormGasto(balanceNotifier, _addTransacao);
      },
    );
  }

  final ImagePicker _picker = ImagePicker();
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadUserName();
  }

  Future<void> _loadProfileImage() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      setState(() {
        _profileImageUrl = doc['profileImageUrl'];
      });
    }
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Nome do Usuário';
    });
  }

  void _updateUserName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = newName;
    });
    prefs.setString('userName', newName);
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        final storageRef =
            FirebaseStorage.instance.ref().child('profileImages/$userId.jpg');
        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'profileImageUrl': downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
        });
      }
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final avaliableHeight = mediaQuery.size.height - mediaQuery.padding.top;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : AssetImage('lib\assets\images\default-profile.png')
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 10),
                   Text(_userName, style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            ListTile(
              title: const Text('Informações Pessoais'),
              onTap: _openPersonalInfoScreen,
            ),
            ListTile(
              title: const Text('Sair'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: GestureDetector(
          onTap: _openDrawer,
          child: Container(
            margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: CircleAvatar(
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!) as ImageProvider
                  : const AssetImage('lib/assets/images/default-profile.png')
                      as ImageProvider,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: avaliableHeight * 0.02,
            ),
            CardBalance(
              _openTransactionFormModalGanho,
              balanceNotifier.value['ganhoValue'] ?? 0.0,
              balanceNotifier.value['saldoValue'] ?? 0.0,
              balanceNotifier.value['gastoValue'] ?? 0.0,
            ),
            SizedBox(
              height: avaliableHeight * 0.02,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Container(
                alignment: Alignment.topLeft,
                child: const Text(
                  "Histórico de Transações",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const TransactionList(),
            SizedBox(
              height: avaliableHeight * 0.02,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Container(
                alignment: Alignment.topLeft,
                child: const Text(
                  "Transações Pendentes",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            FutureTransactionList(),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        backgroundColor: Color.fromARGB(255, 59, 66, 72),
        icon: FontAwesomeIcons.plus,
        foregroundColor: Colors.white,
        overlayOpacity: 0.4,
        children: [
          SpeedDialChild(
            shape: const CircleBorder(),
            backgroundColor: Colors.green,
            child: const FaIcon(FontAwesomeIcons.arrowUp),
            label: "Ganho",
            onTap: _openTransactionFormModalGanho,
          ),
          SpeedDialChild(
            shape: const CircleBorder(),
            backgroundColor: Colors.red,
            child: const FaIcon(FontAwesomeIcons.arrowDown),
            label: "Gasto",
            onTap: _openTransactionFormModalGasto,
          ),
          SpeedDialChild(
            shape: const CircleBorder(),
            backgroundColor: Colors.orange,
            child: const FaIcon(FontAwesomeIcons.piggyBank),
            label: "Economias",
            onTap: _openTransactionFormModalCofrinho,
          ),
        ],
      ),
    );
  }
}
