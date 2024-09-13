import 'package:flutter/material.dart';

class AppbarCustomized extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback openForm;

  const AppbarCustomized(this.openForm, {Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Aplicativo Financeiro',
        style: TextStyle(fontSize: 20),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      actions: [],
    );
  }
}
