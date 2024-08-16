// appbar_customized.dart
import 'package:flutter/material.dart';

class AppbarCustomized extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback openForm;

  const AppbarCustomized(this.openForm, {Key? key}) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Aplicativo Financeiro'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      actions: [
        IconButton(
          onPressed: openForm,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
