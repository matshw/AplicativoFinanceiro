import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

final NumberFormat currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

class GoalsScreen extends StatefulWidget {
  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DateFormat _monthFormatter = DateFormat('yyyy-MM');

  final Map<String, FaIcon> _categories = {
    'Alimentação': const FaIcon(FontAwesomeIcons.burger),
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

  Map<String, double> _currentGoals = {};
  Map<String, double> _currentExpenses = {};
  Map<String, Map<String, dynamic>> _archives = {};
  String? _selectedMonth;
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = _monthFormatter.format(DateTime.now());
    _loadArchives();
    _loadCurrentData();
  }

  Future<void> _loadArchives() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final archivesDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .doc('archives')
        .get();

    if (archivesDoc.exists) {
      final data = archivesDoc.data()!;
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

      setState(() {
        _archives = data.map((month, goals) {
          return MapEntry(month, Map<String, dynamic>.from(goals));
        });

        _availableMonths = _archives.keys
            .where((month) => month.compareTo(currentMonth) < 0)
            .toList()
          ..add(_selectedMonth!)
          ..sort();
      });
    }
  }

  Future<void> _loadCurrentData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final goalsDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .doc('current')
        .get();

    if (goalsDoc.exists) {
      setState(() {
        _currentGoals = Map<String, double>.from(goalsDoc.data()!);
      });
    }

    final expensesSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transacao')
        .get();

    final expensesByCategory = <String, double>{};
    for (var doc in expensesSnapshot.docs) {
      final category = doc['categoria'];
      final value = doc['valor'];
      expensesByCategory[category] =
          (expensesByCategory[category] ?? 0) + value;
    }

    setState(() {
      _currentExpenses = expensesByCategory;
    });
  }

  void _selectMonth(String? month) {
    setState(() {
      _selectedMonth = month;
    });
  }

  Map<String, double> _getSelectedGoals() {
    if (_selectedMonth == _monthFormatter.format(DateTime.now())) {
      return Map<String, double>.from(_currentGoals);
    }

    final selectedData = _archives[_selectedMonth!] ?? {};
    return selectedData.map((key, value) => MapEntry(key, value as double));
  }

  Future<void> _showGoalDialog(String category) async {
    final controller = TextEditingController(
      text: _currentGoals[category]?.toString() ?? '',
    );
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Definir Meta para $category"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Valor da Meta"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                final user = _auth.currentUser;
                if (user == null) return;

                final value = double.tryParse(controller.text) ?? 0.0;

                await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('goals')
                    .doc('current')
                    .set(
                  {category: value},
                  SetOptions(merge: true),
                );

                setState(() {
                  _currentGoals[category] = value;
                });

                Navigator.of(context).pop();
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }

  void _selectCategoryForGoal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Selecione uma Categoria"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories.keys.elementAt(index);
                final icon = _categories[category]!;
                return ListTile(
                  leading: icon,
                  title: Text(category),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showGoalDialog(category);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalTile(
      String category, double goal, double expense, FaIcon icon) {
    final progress = (goal > 0) ? (expense / goal) : 0.0;

    return ListTile(
      leading: icon,
      title: Text(
        category,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Meta: ${currencyFormatter.format(goal)}",
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            "Gasto: ${currencyFormatter.format(expense)}",
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            "Percentual: ${(progress * 100).toStringAsFixed(1)}%",
            style: TextStyle(
              color: progress > 1.0
                  ? Color.fromARGB(255, 244, 111, 101)
                  : Color.fromARGB(255, 90, 204, 94),
              fontWeight: FontWeight.bold,
            ),
          ),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade300,
            color: progress > 1.0
                ? Color.fromARGB(255, 244, 111, 101)
                : Color.fromARGB(255, 90, 204, 94),
          ),
        ],
      ),
      trailing: _selectedMonth == _monthFormatter.format(DateTime.now())
          ? IconButton(
              icon: const Icon(Icons.edit,
                  color: Color.fromRGBO(179, 210, 241, 1)),
              onPressed: () => _showGoalDialog(category),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedGoals = _getSelectedGoals();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          "Economias",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: _monthFormatter.format(DateTime.now()),
                  child: const Text("Mês Atual"),
                ),
                ..._availableMonths.map((month) {
                  return PopupMenuItem(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
              ];
            },
            onSelected: (selectedMonth) {
              _selectMonth(selectedMonth);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: selectedGoals.keys.length,
        itemBuilder: (context, index) {
          final category = selectedGoals.keys.elementAt(index);
          final goal = selectedGoals[category] ?? 0.0;
          final expense = _currentExpenses[category] ?? 0.0;
          final icon = _categories[category] ??
              const FaIcon(FontAwesomeIcons.circleQuestion);

          return _buildGoalTile(category, goal, expense, icon);
        },
      ),
      floatingActionButton: SpeedDial(
        backgroundColor: Color.fromARGB(255, 59, 66, 72),
        icon: FontAwesomeIcons.plus,
        foregroundColor: Colors.white,
        overlayOpacity: 0.4,
        onPress: _selectCategoryForGoal,
      ),
    );
  }
}
