import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SelectCategoryScreen extends StatelessWidget {
  final Function(String, FaIcon) onCategorySelected;

  SelectCategoryScreen({required this.onCategorySelected});

  // Mapa com as categorias e seus ícones
  final Map<String, FaIcon> _categories = {
    'Salário': const FaIcon(FontAwesomeIcons.sackDollar),
    'Freelance': const FaIcon(FontAwesomeIcons.briefcase),
    'Venda': const FaIcon(FontAwesomeIcons.circleDollarToSlot),
    'Comissão': const FaIcon(FontAwesomeIcons.handHoldingDollar),
    'Presente': const FaIcon(FontAwesomeIcons.gift),
    'Consultoria': const FaIcon(FontAwesomeIcons.magnifyingGlassDollar),
    'Outros': const FaIcon(FontAwesomeIcons.circleQuestion),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Categoria'),
      ),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          String categoryName = _categories.keys.elementAt(index);
          FaIcon categoryIcon = _categories[categoryName]!;

          return ListTile(
            leading: categoryIcon,
            title: Text(categoryName),
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
