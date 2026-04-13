import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ultimo_refugio/core/services/supabase_service.dart';

class ColonyScreen extends StatefulWidget {
  const ColonyScreen({super.key});

  @override
  State<ColonyScreen> createState() => _ColonyScreenState();
}

class _ColonyScreenState extends State<ColonyScreen> {
  Future<Map<String, dynamic>?> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final membership = await supabase
        .from('colony_members')
        .select('colony_id, role')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    if (membership == null) return null;

    final colonyId = membership['colony_id'];

    final colony = await supabase
        .from('colonies')
        .select('name, join_code')
        .eq('id', colonyId)
        .single();

    final members = await supabase
        .from('colony_members')
        .select('user_id, role, profiles(username)')
        .eq('colony_id', colonyId);

    return {
      'colony_id': colonyId,
      'name': colony['name'],
      'join_code': colony['join_code'],
      'role': membership['role'],
      'members': members,
    };
  }

  Future<void> _leaveColony(String colonyId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('colony_members')
        .delete()
        .eq('user_id', user.id)
        .eq('colony_id', colonyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colonia'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No tienes colonia'));
          }

          final members = data['members'] as List<dynamic>;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                data['name'],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              /// Código
              Card(
                child: ListTile(
                  title: const Text('Código de invitación'),
                  subtitle: Text(data['join_code']),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: data['join_code']),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copiado')),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Miembros
              const Text(
                'Miembros',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              ...members.map((m) {
                final username = m['profiles']?['username'] ?? 'Usuario';
                final role = m['role'];

                return Card(
                  child: ListTile(
                    title: Text(username),
                    trailing: Text(role),
                  ),
                );
              }),

              const SizedBox(height: 30),

              /// Salir
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Salir de la colonia'),
                      content: const Text('¿Estás seguro?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Salir'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _leaveColony(data['colony_id']);

                    if (!mounted) return;
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Salir de la colonia'),
              ),
            ],
          );
        },
      ),
    );
  }
}