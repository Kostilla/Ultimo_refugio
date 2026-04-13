import 'package:flutter/material.dart';
import 'package:ultimo_refugio/core/services/supabase_service.dart';
import 'package:ultimo_refugio/features/colony/presentation/colony_screen.dart';
import 'package:ultimo_refugio/features/profile/presentation/profile_screen.dart';
import 'buildings_screen.dart';
import 'events_screen.dart';
import 'expeditions_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _openEventsTab() {
    setState(() {
      _index = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ColonyBaseScreen(
        onOpenEvents: _openEventsTab,
      ),
      const BuildingsScreen(),
      const ExpeditionsScreen(),
      const EventsScreen(),
      const ColonyScreen(),
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
            icon: Icon(Icons.explore),
            label: 'Exped.',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Colonia',
          ),
        ],
      ),
    );
  }
}

class ColonyBaseScreen extends StatelessWidget {
  const ColonyBaseScreen({
    super.key,
    required this.onOpenEvents,
  });

  final VoidCallback onOpenEvents;

  int _cap(int value, int max) => value > max ? max : value;

  String _buildingLabel(String type) {
    switch (type) {
      case 'generator':
        return 'Generador';
      case 'farm':
        return 'Invernadero';
      case 'water':
        return 'Depuradora';
      case 'factory':
        return 'Taller';
      case 'storage':
        return 'Almacén';
      default:
        return type;
    }
  }

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

    final buildings = await supabase
        .from('colony_buildings')
        .select()
        .eq('colony_id', colonyId);

    if (resources == null) {
      return {
        'role': membership['role'],
        'name': colony['name'],
        'join_code': colony['join_code'],
        'resources': null,
        'buildings': buildings,
        'rates': {
          'food': 0,
          'water': 0,
          'energy': 0,
          'metal': 0,
        },
        'capacity': 0,
        'active_event_count': 0,
      };
    }

    int getLevel(String type) {
      final filtered = buildings.where((e) => e['type'] == type).toList();
      if (filtered.isEmpty) return 1;
      return (filtered.first['level'] as num).toInt();
    }

    final storageLevel = getLevel('storage');
    final capacity = storageLevel * 500;

    final foodRate = getLevel('farm');
    final waterRate = getLevel('water');
    final energyRate = getLevel('generator') * 2;
    final metalRate = getLevel('factory');

    final rawLastUpdated = resources['last_updated'];
    final lastUpdated = rawLastUpdated == null
        ? null
        : DateTime.parse(rawLastUpdated.toString()).toUtc();

    if (lastUpdated != null) {
      final now = DateTime.now().toUtc();
      final diffMinutes = now.difference(lastUpdated).inMinutes;

      if (diffMinutes > 0 && diffMinutes < 1440) {
        final updatedResources = {
          'food': _cap(
            (resources['food'] as int) + diffMinutes * foodRate,
            capacity,
          ),
          'water': _cap(
            (resources['water'] as int) + diffMinutes * waterRate,
            capacity,
          ),
          'energy': _cap(
            (resources['energy'] as int) + diffMinutes * energyRate,
            capacity,
          ),
          'metal': _cap(
            (resources['metal'] as int) + diffMinutes * metalRate,
            capacity,
          ),
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

    final activeEvents = await supabase
        .from('colony_events')
        .select('id')
        .eq('colony_id', colonyId)
        .eq('status', 'active');

    return {
      'role': membership['role'],
      'name': colony['name'],
      'join_code': colony['join_code'],
      'resources': resources,
      'buildings': buildings,
      'rates': {
        'food': foodRate,
        'water': waterRate,
        'energy': energyRate,
        'metal': metalRate,
      },
      'capacity': capacity,
      'active_event_count': activeEvents.length,
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

          final resources = data['resources'] as Map<String, dynamic>?;
          final rates = data['rates'] as Map<String, dynamic>;
          final buildings = (data['buildings'] as List<dynamic>? ?? []);
          final capacity = data['capacity'];
          final activeEventCount = data['active_event_count'] as int? ?? 0;

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '${data['name']}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    title: const Text('Código'),
                    subtitle: Text('${data['join_code']}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Rol'),
                    subtitle: Text('${data['role']}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Capacidad máxima'),
                    trailing: Text('$capacity'),
                  ),
                ),
                if (activeEventCount > 0)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: const Text('Eventos activos'),
                      subtitle: const Text('Pulsa para verlos'),
                      trailing: Text('$activeEventCount'),
                      onTap: onOpenEvents,
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
                      trailing: Text(
                        '${resources['food']} / $capacity (+${rates['food']}/min)',
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('💧 Agua'),
                      trailing: Text(
                        '${resources['water']} / $capacity (+${rates['water']}/min)',
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('⚡ Energía'),
                      trailing: Text(
                        '${resources['energy']} / $capacity (+${rates['energy']}/min)',
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('🔩 Metal'),
                      trailing: Text(
                        '${resources['metal']} / $capacity (+${rates['metal']}/min)',
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Última actualización'),
                      subtitle: Text('${resources['last_updated']}'),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Edificios',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...buildings.map((b) {
                  return Card(
                    child: ListTile(
                      title: Text(_buildingLabel('${b['type']}')),
                      trailing: Text('Nivel ${b['level']}'),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}