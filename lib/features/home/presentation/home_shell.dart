import 'package:flutter/material.dart';
import 'package:ultimo_refugio/core/services/supabase_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ColonyBaseScreen(),
      const Scaffold(body: Center(child: Text('Edificios'))),
      const Scaffold(body: Center(child: Text('Eventos'))),
      const Scaffold(body: Center(child: Text('Colonia'))),
      const Scaffold(body: Center(child: Text('Perfil'))),
    ];

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

class ColonyBaseScreen extends StatelessWidget {
  const ColonyBaseScreen({super.key});

  Future<Map<String, dynamic>?> _loadColony() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final membership = await supabase
        .from('colony_members')
        .select('role, colony_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (membership == null) return null;

    final colony = await supabase
        .from('colonies')
        .select('name, join_code, created_at')
        .eq('id', membership['colony_id'])
        .single();

    return {
      'role': membership['role'],
      'name': colony['name'],
      'join_code': colony['join_code'],
      'created_at': colony['created_at'],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Base de la colonia'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadColony(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error cargando colonia: ${snapshot.error}'),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('No perteneces a ninguna colonia'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.vpn_key),
                    title: const Text('Código de unión'),
                    subtitle: Text('${data['join_code']}'),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.badge),
                    title: const Text('Tu rol'),
                    subtitle: Text('${data['role']}'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
