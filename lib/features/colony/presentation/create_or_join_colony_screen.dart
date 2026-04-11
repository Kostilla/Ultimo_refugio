import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateOrJoinColonyScreen extends StatelessWidget {
  const CreateOrJoinColonyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Colonia')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/home');
          },
          child: const Text('Entrar al juego'),
        ),
      ),
    );
  }
}
