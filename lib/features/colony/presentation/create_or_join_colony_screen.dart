import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'colony_providers.dart';

class CreateOrJoinColonyScreen extends ConsumerStatefulWidget {
  const CreateOrJoinColonyScreen({super.key});

  @override
  ConsumerState<CreateOrJoinColonyScreen> createState() =>
      _CreateOrJoinColonyScreenState();
}

class _CreateOrJoinColonyScreenState
    extends ConsumerState<CreateOrJoinColonyScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    ref.read(colonyLoadingProvider.notifier).state = true;

    try {
      await ref.read(colonyRepositoryProvider).createColony(
            _nameController.text,
          );

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      ref.read(colonyLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _join() async {
    ref.read(colonyLoadingProvider.notifier).state = true;

    try {
      await ref.read(colonyRepositoryProvider).joinColony(
            _codeController.text,
          );

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      ref.read(colonyLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(colonyLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colonia'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            const Text(
              'Bienvenido a tu refugio',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea una colonia nueva o únete a una existente con un código.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Crear colonia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la colonia',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: loading ? null : _create,
                      child: Text(
                        loading ? 'Procesando...' : 'Crear colonia',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Unirse a colonia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      enabled: !loading,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Código de unión',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: loading ? null : _join,
                      child: const Text('Unirse'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}