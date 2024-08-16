import 'package:flutter/material.dart';
import 'package:tcc/screens/screen_economies.dart';
import 'package:tcc/screens/screen_main.dart';
import 'package:tcc/screens/screen_reports.dart';
import 'package:tcc/screens/screen_transactions.dart';

class ScreenTabs extends StatefulWidget {
  @override
  State<ScreenTabs> createState() => _ScreenTabsState();
}

class _ScreenTabsState extends State<ScreenTabs> {
  int _selectedScreenIndex = 0;

  final List<Map<String, Object>> _screens = [
    {
      'title': "Principal",
      'screen': ScreenMain(),
    },
    {
      'title': "Transações",
      'screen': TransactionsScreen(),
    },
    {
      'title': "Economias",
      'screen': EconomiesScreen(),
    },
    {
      'title': "Relatórios",
      'screen': ReportsScreen(),
    },
  ];

  void _selectedScreen(int index) {
    setState(() {
      _selectedScreenIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedScreenIndex == 0
          ? null
          : AppBar(
              title: Text(_screens[_selectedScreenIndex]['title'] as String),
            ),
      body: _screens[_selectedScreenIndex]['screen'] as Widget,
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectedScreen,
        currentIndex: _selectedScreenIndex,
        unselectedItemColor: Colors.white,
        selectedItemColor: Colors.black,
        backgroundColor: Theme.of(context).colorScheme.primary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Principal",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: "Transações",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money),
            label: "Economias",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.broken_image_outlined),
            label: "Relatórios",
          ),
        ],
      ),
    );
  }
}
