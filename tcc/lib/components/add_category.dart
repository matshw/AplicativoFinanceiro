import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tcc/utils/firestore_service.dart';

class AddCategoryScreen extends StatefulWidget {
  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  FaIcon? _selectedIcon;

  final List<FaIcon> _icons = [
    FaIcon(FontAwesomeIcons.burger),
    FaIcon(FontAwesomeIcons.shirt),
    FaIcon(FontAwesomeIcons.car),
    FaIcon(FontAwesomeIcons.gift),
    FaIcon(FontAwesomeIcons.book),
  ];

  final FirestoreService _firestoreService = FirestoreService();

  void _saveCategory() {
    if (_nameController.text.isNotEmpty && _selectedIcon != null) {
      _firestoreService
          .addCategory(_nameController.text, _selectedIcon!.icon!.codePoint)
          .then((_) {
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Nova Categoria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nome da Categoria'),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: _icons.map((icon) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            _selectedIcon == icon ? Colors.blue : Colors.grey,
                      ),
                    ),
                    child: icon,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveCategory,
              child: Text('Salvar Categoria'),
            ),
          ],
        ),
      ),
    );
  }
}
