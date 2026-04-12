import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'colony_providers.dart';

class CreateOrJoinColonyScreen extends ConsumerStatefulWidget {
  const CreateOrJoinColonyScreen({super.key});

  @override
  ConsumerState<CreateOrJoinColonyScreen> createState() => _CreateOrJoinColonyScreenState();
}

class _CreateOrJoinColonyScreenState extends ConsumerState<CreateOrJoinColonyScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  Future<void> _create() async {
    ref.read(colonyLoadingProvider.notifier).state = true;

    try {
      await ref.read(colonyRepositoryProvider).createColony(
            _nameController.text,
          );

      if (mounted) context.go('/home');
    } catch (e) {
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

      if (mounted) context.go('/home');
    } catch (e) {
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
      appBar: AppBar(title: const Text('Colonia')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Crear colonia'),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            ElevatedButton(
              onPressed: loading ? null : _create,
              child: const Text('Crear'),
            ),
            const Divider(),
            const Text('Unirse a colonia'),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Código'),
            ),
            ElevatedButton(
              onPressed: loading ? null : _join,
              child: const Text('Unirse'),
            ),
          ],
        ),
      ),
    );
  }
}