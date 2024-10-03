import 'package:flutter/material.dart';

class AppbarCofrinho extends StatelessWidget implements PreferredSizeWidget {
  const AppbarCofrinho({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Economias',
        style: TextStyle(fontSize: 20),
      ),
      backgroundColor: Color.fromRGBO(78,105,130, 1.0),
      actions: [],
    );
  }
}
