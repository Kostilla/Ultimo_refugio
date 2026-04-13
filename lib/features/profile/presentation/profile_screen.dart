import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ultimo_refugio/core/services/supabase_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await supabase.auth.signOut();
    if (!context.mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final email = user?.email ?? 'Sin email';
    final userId = user?.id ?? 'Sin ID';
    final username = user?.userMetadata?['username'] ?? 'Sin nombre';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.account_circle, size: 84),
          const SizedBox(height: 16),
          Text(
            '$username',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              title: const Text('Email'),
              subtitle: Text(email),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('ID de usuario'),
              subtitle: Text(userId),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
