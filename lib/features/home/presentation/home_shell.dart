import 'package:flutter/material.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final screens = const [
    Center(child: Text('Base')),
    Center(child: Text('Edificios')),
    Center(child: Text('Eventos')),
    Center(child: Text('Colonia')),
    Center(child: Text('Perfil')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Base'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Edificios'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Eventos'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Colonia'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
