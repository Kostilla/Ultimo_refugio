import 'package:flutter/material.dart';
import 'package:ultimo_refugio/core/services/supabase_service.dart';
import 'buildings_screen.dart';

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
      const BuildingsScreen(),
      const Scaffold(
        body: Center(child: Text('Eventos')),
      ),
      const Scaffold(
        body: Center(child: Text('Colonia')),
      ),
      const Scaffold(
        body: Center(child: Text('Perfil')),
      ),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Base',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Edificios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Colonia',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class ColonyBaseScreen extends StatelessWidget {
  const ColonyBaseScreen({super.key});

  int _cap(int value, int max) => value > max ? max : value;

  Future<Map<String, dynamic>?> _loadColony() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final membership = await supabase
        .from('colony_members')
        .select('role, colony_id')
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

    final resources = await supabase
        .from('colony_resources')
        .select()
        .eq('colony_id', colonyId)
        .maybeSingle();

    if (resources == null) {
      return {
        'role': membership['role'],
        'name': colony['name'],
        'join_code': colony['join_code'],
        'resources': null,
      };
    }

    final rawLastUpdated = resources['last_updated'];
    final lastUpdated = rawLastUpdated == null
        ? null
        : DateTime.parse(rawLastUpdated.toString()).toUtc();

    if (lastUpdated != null) {
      final now = DateTime.now().toUtc();
      final diffMinutes = now.difference(lastUpdated).inMinutes;

      if (diffMinutes > 0 && diffMinutes < 1440) {
        final updatedResources = {
          'food': _cap((resources['food'] as int) + diffMinutes * 1, 500),
          'water': _cap((resources['water'] as int) + diffMinutes * 1, 500),
          'energy': _cap((resources['energy'] as int) + diffMinutes * 2, 500),
          'metal': _cap((resources['metal'] as int) + diffMinutes * 1, 500),
          'last_updated': now.toIso8601String(),
        };

        await supabase
            .from('colony_resources')
            .update(updatedResources)
            .eq('colony_id', colonyId);

        resources['food'] = updatedResources['food'];
        resources['water'] = updatedResources['water'];
        resources['energy'] = updatedResources['energy'];
        resources['metal'] = updatedResources['metal'];
        resources['last_updated'] = updatedResources['last_updated'];
      }
    }

    return {
      'role': membership['role'],
      'name': colony['name'],
      'join_code': colony['join_code'],
      'resources': resources,
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('No tienes colonia'),
            );
          }

          final resources = data['resources'];

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
              Card(
                child: ListTile(
                  title: const Text('Código'),
                  subtitle: Text(data['join_code']),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Rol'),
                  subtitle: Text(data['role']),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Recursos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (resources != null) ...[
                Card(
                  child: ListTile(
                    title: const Text('🍖 Comida'),
                    trailing: Text('${resources['food']}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('💧 Agua'),
                    trailing: Text('${resources['water']}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('⚡ Energía'),
                    trailing: Text('${resources['energy']}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('🔩 Metal'),
                    trailing: Text('${resources['metal']}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Última actualización'),
                    subtitle: Text('${resources['last_updated']}'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}