import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GoalsScreen extends StatefulWidget {
  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, FaIcon> _categories = {
    'Comida': FaIcon(FontAwesomeIcons.burger),
    'Roupas': FaIcon(FontAwesomeIcons.shirt),
    'Lazer': FaIcon(FontAwesomeIcons.futbol),
    'Transporte': FaIcon(FontAwesomeIcons.bicycle),
    'Saúde': FaIcon(FontAwesomeIcons.suitcaseMedical),
    'Presentes': FaIcon(FontAwesomeIcons.gift),
    'Educação': FaIcon(FontAwesomeIcons.book),
    'Beleza': FaIcon(FontAwesomeIcons.paintbrush),
    'Emergência': FaIcon(FontAwesomeIcons.hospital),
    'Reparos': FaIcon(FontAwesomeIcons.hammer),
    'Streaming': FaIcon(FontAwesomeIcons.tv),
    'Serviços': FaIcon(FontAwesomeIcons.clipboard),
    'Tecnologia': FaIcon(FontAwesomeIcons.laptop),
    'Outros': FaIcon(FontAwesomeIcons.circleQuestion),
  };

  Map<String, double> _goals = {};
  Map<String, double> _expenses = {};
  List<String> _activeCategories = [];

  @override
  void initState() {
    super.initState();
    checkAndResetGoals();
    _fetchGoals();
    _fetchExpenses();
  }

  Future<void> checkAndResetGoals() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final firstDayThisMonth = DateTime(today.year, today.month, 1);
    final firstDayNextMonth = DateTime(today.year, today.month + 1, 1);

    final goalsRef =
        _firestore.collection('users').doc(user.uid).collection('goals');
    final currentGoalsDoc = await goalsRef.doc('current').get();

    if (!currentGoalsDoc.exists || today.isAtSameMomentAs(firstDayThisMonth)) {
      if (currentGoalsDoc.exists) {
        await goalsRef.doc('archives').set({
          '${today.year}-${today.month.toString().padLeft(2, '0')}':
              currentGoalsDoc.data()
        }, SetOptions(merge: true));
      }

      Map<String, dynamic> newGoals = {};
      currentGoalsDoc.data()?.forEach((key, value) {
        newGoals[key] = 0.0;
      });
      await goalsRef.doc('current').set(newGoals);
    }
  }

  Future<void> _fetchGoals() async {
    final user = _auth.currentUser;
    if (user != null) {
      final goalsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc('current')
          .get();
      if (goalsSnapshot.exists) {
        setState(() {
          _goals = Map<String, double>.from(goalsSnapshot.data()!);
          _activeCategories = _goals.keys.toList();
        });
      }
    }
  }

  Future<void> _fetchExpenses() async {
    final user = _auth.currentUser;
    if (user != null) {
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
        if (!_activeCategories.contains(category)) {
          _activeCategories.add(category);
        }
      }
      setState(() {
        _expenses = expensesByCategory;
      });
    }
  }

  void _addOrEditGoal(String category, double value) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc('current')
          .set({category: value}, SetOptions(merge: true));
      setState(() {
        _goals[category] = value;
        if (!_activeCategories.contains(category)) {
          _activeCategories.add(category);
        }
      });
    }
  }

  void _removeGoal(String category) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc('current')
          .update({category: FieldValue.delete()});
      setState(() {
        _goals.remove(category);
        if (!_expenses.containsKey(category)) {
          _activeCategories.remove(category);
        }
      });
    }
  }

  Future<void> _showGoalDialog(String category) async {
    final controller =
        TextEditingController(text: _goals[category]?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Definir meta para $category"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Valor da Meta"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(controller.text) ?? 0.0;
                _addOrEditGoal(category, value);
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
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                String category = _categories.keys.elementAt(index);
                FaIcon icon = _categories[category]!;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: ListView.builder(
            itemCount: _activeCategories.length,
            itemBuilder: (context, index) {
              final category = _activeCategories[index];
              final icon = _categories[category] ??
                  FaIcon(FontAwesomeIcons.circleQuestion);
              final goal = _goals[category] ?? 0.0;
              final expense = _expenses[category] ?? 0.0;
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
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade300,
                      color: progress > 1.0 ? Colors.red : Colors.green,
                    ),
                    Text(
                      goal > 0
                          ? "Gasto: R\$${expense.toStringAsFixed(2)} de R\$${goal.toStringAsFixed(2)} (${(progress * 100).clamp(0.0, 100.0).toStringAsFixed(1)}%)"
                          : "Sem meta definida",
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showGoalDialog(category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeGoal(category),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _selectCategoryForGoal,
      ),
    );
  }
}
