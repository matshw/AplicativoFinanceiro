import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SelectGastoCategoryScreen extends StatelessWidget {
  final Function(String, FaIcon) onCategorySelected;

  SelectGastoCategoryScreen({required this.onCategorySelected});

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
    'Servicos': const FaIcon(FontAwesomeIcons.clipboard),
    'Tecnologia': const FaIcon(FontAwesomeIcons.laptop),
    'Outros': const FaIcon(FontAwesomeIcons.circleQuestion),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
                foregroundColor: Colors.white,

        title: const Text(
          'Selecionar Categoria',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          String categoryName = _categories.keys.elementAt(index);
          FaIcon categoryIcon = _categories[categoryName]!;

          return ListTile(
            leading: categoryIcon,
            iconColor: Colors.white,
            title: Text(
              categoryName,
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              onCategorySelected(categoryName, categoryIcon);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}
